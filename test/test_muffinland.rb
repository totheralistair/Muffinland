require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'

require_relative '../src/muffinland.rb'
require_relative '../src/ml_request.rb'

#=== utilities ======================
class Hash
def extract_per( sampleHash )  # {:a=>1, :b=>2, :c=>3}.extract_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
    sampleHash.inject({}) { |subset, (k,v) | subset[k] = self[k] ; subset }
  end
end


#=== different ways of driving the app ======================
def request_via_API( app, method, path, params={} ) # app should be Muffinland (hexagon API)
  env = Rack::MockRequest.env_for(path, {:method => method, :params=>params}  )
  rr = Rack::Request.new(env)
  puts "and request.POST=" + rr.POST.inspect
  request = Ml_RackRequest.new( rr )
puts "About to send request:" + request.inspect
  app.handle request
end


def request_via_rack_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
  request = Rack::MockRequest.new(app)
  request.request(method, path, {:params=>params}) #this sends the request through the Rack call(env) chain
end



class TestRequests < Test::Unit::TestCase
#=================================================
  def test_00_emptyDB_is_special_case
    puts "test_00_emptyDB starting..."
    app = Muffinland.new

    mlResponse = request_via_API( app, "GET", '/' )
    exp = {:out_action=>"EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/aaa' )
    exp =  {:out_action=>"EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    puts "test_00_emptyDB done"
  end


#=================================================
  def test_01_posts_return_contents
    puts "test_01_posts starting..."
    app = Muffinland.new

    mlResponse = request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    exp = {
        :out_action => "GET_named_page",
        :muffin_id => 0,
        :dangerously_all_muffins_raw => ["a"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    exp = {
    :out_action=> "GET_named_page",
    :muffin_id => 1,
    :dangerously_all_muffins_raw => ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp

    puts "test_01_posts done"
  end


#=================================================
  def test_02_can_post_and_get_even_404
    puts "test_02_postAndGet starting..."
    app = Muffinland.new

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"c" } )
    mlResponse = request_via_API( app, "GET", '/1' )
    exp = {
        :out_action=> "GET_named_page",
        :muffin_id => 1,
        :muffin_body => "b",
        :dangerously_all_muffins_raw => ["a", "b", "c"]
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/77' )
    exp = {
        :out_action=> "404",
        :muffin_id => nil,
        :muffin_body => nil,
        :dangerously_all_muffins_raw => ["a", "b", "c"]
    }
    mlResponse.extract_per( exp ).should == exp

    puts "test_02_postAndGet done"
  end

#=================================================
  def test_03_can_change_a_muffin
    puts "test_03_can_change_a_muffin starting..."
    app = Muffinland.new

    test_image = "/Users/alistaircockburn/Desktop/2x2.png"
    file = Rack::Test::UploadedFile.new(test_image, "image/png")

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    mlResponse = request_via_API( app, "POST", '/ignored',{ "Change"=>"Change", "MuffinNumber"=> "0", "MuffinContents"=>"b" } )
    exp = {
        :out_action=> "GET_named_page",
        :muffin_id => 0,
        :muffin_body => "b",
        :dangerously_all_muffins_raw => ["b"]
    }
    mlResponse.extract_per( exp ).should == exp

    puts "test_03_can_change_a_muffin done"
  end


#=================================================
  def test_04_can_tag_a_muffin_to_another
    puts "test_04_can_tag_a_muffin_to_another starting..."
    app = Muffinland.new

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    mlResponse = request_via_API( app, "POST", '/ignored',{ "Tag"=>"Tag", "MuffinNumber"=> "0", "CollectorNumber"=>"1" } )
    exp = {
        :out_action=> "GET_named_page",
        :muffin_id => 0,
        :muffin_body => "a",
        :tags => Set.new([1])  ,
        :dangerously_all_muffins_raw => ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp

    puts "test_04_can_tag_a_muffin_to_another done"
  end

#=================================================
  def test_05_can_upload_file   # sooooo doesn't work......
    puts "test_05_can_upload_file starting..."
    app = Muffinland.new

    input = <<EOF
--AaB03x\r
content-disposition: form-data; name="reply"\r
\r
yes\r
--AaB03x\r
content-disposition: form-data; name="fileupload"; filename="dj.jpg"\r
Content-Type: image/jpeg\r
Content-Transfer-Encoding: base64\r
\r
/9j/4AAQSkZJRgABAQAAAQABAAD//gA+Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcg\r
--AaB03x--\r
EOF

    req = Rack::Request.new Rack::MockRequest.env_for("/",
                                                      "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                                      "CONTENT_LENGTH" => input.size,
                                                      :input => input)
#    req.POST.should.include "fileupload"
#    req.POST.should.include "reply"

    puts req.content_length== input.size
    puts req.media_type== 'multipart/form-data'
    puts req.media_type_params['boundary']== 'AaB03x'

    puts req.POST

    puts req.POST["reply"]== "yes"

    f = req.POST["fileupload"]
    puts f[:type]== "image/jpeg"
    puts f[:filename]== "dj.jpg"
#    puts f[:tempfile].size.should.equal 76

# req.should.be.form_data
# req.content_length.should.equal input.size
# req.media_type.should.equal 'multipart/form-data'
# req.media_type_params.should.include 'boundary'
# req.media_type_params['boundary'].should.equal 'AaB03x'
#
# req.POST["reply"].should.equal "yes"
#
# f = req.POST["fileupload"]
# f.should.be.kind_of Hash
# f[:type].should.equal "image/jpeg"
# f[:filename].should.equal "dj.jpg"
# f.should.include :tempfile
# f[:tempfile].size.should.equal 76

    mlRequest = request_via_API( app, "POST", '/ignored',
                                 "Upload"=>"Upload",
                                 "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                 "CONTENT_LENGTH" => input.size,
                                 :input => input)
    puts "Received mlRequet:#{mlRequest.inspect}"


    exp = {
    :out_action=> "GET_named_page",
    }
    exp.should == exp

    puts "test_05_can_upload_file done"
  end

=begin
    mlRequest = request_via_API( app, "POST", '/ignored',
                                 {"Upload"=>"Upload",
                                  "file"=>Rack::Test::UploadedFile.new("/Users/alistaircockburn/Desktop/2x2copy.png", "image/png", true),
                                  "CONTENT_TYPE"=>"multipart/form-data; boundary=----WebKitFormBoundaryepWBaZrLmDjRxcg8"
                                 } )

    { “file” => Rack::Test::UploadedFile("/Users/alistaircockburn/Desktop/2x2copy.png", "image/png", true  }
    f = UploadedFile.new("/Users/alistaircockburn/Desktop/2x2copy.png", "image/png", true )
    mlRequest = request_via_API(
        app,
        "POST",
        '/ignored',
        {"Upload"=>"Upload",
         "file"=>"/Users/alistaircockburn/Desktop/2x2copy.png"
          } )
{
             :filename=>"2x2.png",
             :type=>"image/png",
             :name=>"file"},
             :tempfile =>

=end
#===============================
=begin
  input = <<EOF
--AaB03x\r
content-disposition: form-data; name="reply"\r
\r
yes\r
--AaB03x\r
content-disposition: form-data; name="fileupload"; filename="dj.jpg"\r
Content-Type: image/jpeg\r
Content-Transfer-Encoding: base64\r
\r
/9j/4AAQSkZJRgABAQAAAQABAAD//gA+Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcg\r
--AaB03x--\r
EOF
  req = Rack::Request.new Rack::MockRequest.env_for("/",
                                                    "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                                    "CONTENT_LENGTH" => input.size,
                                                    :input => input)
=end

#=================================================
# text muffin:
#<Ml_RackRequest:0x000001012cbad0 @myRequest=#<Rack::Request:0x000001012cbc10
# @env={"CONTENT_LENGTH"=>"24",
#   "CONTENT_TYPE"=>"application/x-www-form-urlencoded", "GATEWAY_INTERFACE"=>"CGI/1.1", "PATH_INFO"=>"/", "QUERY_STRING"=>"", "REMOTE_ADDR"=>"127.0.0.1", "REMOTE_HOST"=>"localhost", "REQUEST_METHOD"=>"POST", "REQUEST_URI"=>"http://localhost:9292/", "SCRIPT_NAME"=>"", "SERVER_NAME"=>"localhost", "SERVER_PORT"=>"9292", "SERVER_PROTOCOL"=>"HTTP/1.1", "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/2.1.0/2013-12-25)", "HTTP_HOST"=>"localhost:9292", "HTTP_CONNECTION"=>"keep-alive", "HTTP_CACHE_CONTROL"=>"max-age=0", "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", "HTTP_ORIGIN"=>"http://localhost:9292", "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.143 Safari/537.36", "HTTP_REFERER"=>"http://localhost:9292/", "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch", "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8,fr;q=0.6", "rack.version"=>[1, 2], "rack.input"=>#<Rack::Lint::InputWrapper:0x000001012d3f78 @input=#<StringIO:0x000001012db8e0>>, "rack.errors"=>#<Rack::Lint::ErrorWrapper:0x000001012cbc60 @error=#<IO:<STDERR>>>, "rack.multithread"=>true, "rack.multiprocess"=>false, "rack.run_once"=>false, "rack.url_scheme"=>"http", "HTTP_VERSION"=>"HTTP/1.1", "REQUEST_PATH"=>"/", "Muffinland"=>{"Times"=>{"Arrived"=>"1408905300.6501818"}}, "rack.request.query_string"=>"", "rack.request.query_hash"=>{}, "rack.request.form_input"=>#<Rack::Lint::InputWrapper:0x000001012d3f78 @input=#<StringIO:0x000001012db8e0>>, "rack.request.form_hash"=>{"Add"=>"Add", "MuffinContents"=>"a"}, "rack.request.form_vars"=>"Add=Add&MuffinContents=a"}, @params={"Add"=>"Add", "MuffinContents"=>"a"}>, @log=#<Logger:0x000001012cb7d8 @progname=nil, @level=1, @default_formatter=#<Logger::Formatter:0x000001012cb7b0 @datetime_format=nil>, @formatter=nil, @logdev=#<Logger::LogDevice:0x000001012cb3a0 @shift_size=nil, @shift_age=nil, @filename=nil, @dev=#<IO:<STDOUT>>, @mutex=#<Logger::LogDevice::LogDeviceMutex:0x000001012cb170 @mon_owner=nil, @mon_count=0, @mon_mutex=#<Mutex:0x000001012cb058>>>>>

# /Users/alistaircockburn/Desktop/2x2.png

#<Ml_RackRequest:0x00000101214808
# @myRequest=#<Rack::Request:0x00000101214830
#   @env=
# {"CONTENT_LENGTH"=>"357", "CONTENT_TYPE"=>"multipart/form-data; boundary=----WebKitFormBoundaryepWBaZrLmDjRxcg8", "GATEWAY_INTERFACE"=>"CGI/1.1", "PATH_INFO"=>"/", "QUERY_STRING"=>"", "REMOTE_ADDR"=>"127.0.0.1", "REMOTE_HOST"=>"localhost", "REQUEST_METHOD"=>"POST", "REQUEST_URI"=>"http://localhost:9292/", "SCRIPT_NAME"=>"", "SERVER_NAME"=>"localhost", "SERVER_PORT"=>"9292", "SERVER_PROTOCOL"=>"HTTP/1.1", "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/2.1.0/2013-12-25)", "HTTP_HOST"=>"localhost:9292", "HTTP_CONNECTION"=>"keep-alive", "HTTP_CACHE_CONTROL"=>"max-age=0", "HTTP_ACCEPT"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8", "HTTP_ORIGIN"=>"http://localhost:9292", "HTTP_USER_AGENT"=>"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.143 Safari/537.36", "HTTP_REFERER"=>"http://localhost:9292/", "HTTP_ACCEPT_ENCODING"=>"gzip,deflate,sdch", "HTTP_ACCEPT_LANGUAGE"=>"en-US,en;q=0.8,fr;q=0.6", "rack.version"=>[1, 2], "rack.input"=>#<Rack::Lint::InputWrapper:0x00000101214948 @input=#<StringIO:0x00000101224ff0>>, "rack.errors"=>#<Rack::Lint::ErrorWrapper:0x00000101214880 @error=#<IO:<STDERR>>>, "rack.multithread"=>true, "rack.multiprocess"=>false, "rack.run_once"=>false, "rack.url_scheme"=>"http", "HTTP_VERSION"=>"HTTP/1.1", "REQUEST_PATH"=>"/", "Muffinland"=>{"Times"=>{"Arrived"=>"1408906869.202191"}}, "rack.request.query_string"=>"", "rack.request.query_hash"=>{}, "rack.request.form_input"=>#<Rack::Lint::InputWrapper:0x00000101214948 @input=#<StringIO:0x00000101224ff0>>, "rack.request.form_hash"=>{"Upload"=>"Upload", "file"=>{:filename=>"2x2.png", :type=>"image/png", :name=>"file", :tempfile=>#<Tempfile:/var/folders/2d/9q3nv99167l4w3qwqv8jj8140000gn/T/RackMultipart20140824-29820-st0604>, :head=>"Content-Disposition: form-data; name=\"file\"; filename=\"2x2.png\"\r\nContent-Type: image/png\r\n"}}}, @params={"Upload"=>"Upload", "file"=>{:filename=>"2x2.png", :type=>"image/png", :name=>"file", :tempfile=>#<Tempfile:/var/folders/2d/9q3nv99167l4w3qwqv8jj8140000gn/T/RackMultipart20140824-29820-st0604>, :head=>"Content-Disposition: form-data; name=\"file\"; filename=\"2x2.png\"\r\nContent-Type: image/png\r\n"}}>, @log=#<Logger:0x00000101214740 @progname=nil, @level=1, @default_formatter=#<Logger::Formatter:0x00000101214718 @datetime_format=nil>, @formatter=nil, @logdev=#<Logger::LogDevice:0x00000101214600 @shift_size=nil, @shift_age=nil, @filename=nil, @dev=#<IO:<STDOUT>>, @mutex=#<Logger::LogDevice::LogDeviceMutex:0x000001012145d8 @mon_owner=nil, @mon_count=0, @mon_mutex=#<Mutex:0x00000101214538>>>>>


#  {:filename=>"2x2.png", :type=>"image/png", :name=>"file", :tempfile=>#<Tempfile:/var/folders/2d/9q3nv99167l4w3qwqv8jj8140000gn/T/RackMultipart20140824-29820-st0604>, :head=>"Content-Disposition: form-data; name=\"file\"; filename=\"2x2.png\"\r\nContent-Type: image/png\r\n"}


end

