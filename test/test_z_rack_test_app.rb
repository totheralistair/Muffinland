# test the 4 ways of sending binayr/ascii data/files to the server app. Thx Filip Zrůst ‏@frzng
require 'rack'
require 'test/unit'
require 'rspec/expectations'
#require 'URI'
require_relative '../src/z_rack_test_app'

class TestRequests < Test::Unit::TestCase

  #===============================
  def test_00_can_upload_ascii_file_via_rack
    puts "\n...starting test_00_can_upload_ascii_file_via_rack"

    app = Z_rack_test_app.new
    params = {  description: 'A text file',
                text_source: Rack::Multipart::UploadedFile.new(
                    '/Users/alistaircockburn/Desktop/README.txt')
    }
    env = Rack::MockRequest.env_for( '/', { method: 'POST', params: params } )
    result = app.call env

    body = result[2][0]
    body.should == File.read('/Users/alistaircockburn/Desktop/README.txt')
  end

  #===============================
  def test_00a_can_upload_ascii_file_into_hexagon
    puts "\n...starting test_00a_can_upload_ascii_file_into_hexagon"

    app = Z_hexagonal_app.new
    params = {  description: 'A text file',
                text_source: Rack::Multipart::UploadedFile.new(
                    '/Users/alistaircockburn/Desktop/README.txt')
    }
    env = Rack::MockRequest.env_for( '/', { method: 'POST', params: params } )
    req = Rack::Request.new env
    result = app.handle req

    body = result[2][0]
    body.should == File.read('/Users/alistaircockburn/Desktop/README.txt')
  end

  #===============================
  def test_01_can_upload_binary_file_via_rack
    puts "\n...starting test_01_can_upload_binary_file_via_rack"

    app = Z_rack_test_app.new
    params = {  description: 'A binary file',
                text_source: Rack::Multipart::UploadedFile.new(
                    '/Users/alistaircockburn/Desktop/2x2.png', "image/png", binary=true )
              }
    env = Rack::MockRequest.env_for( '/', { method: 'POST', params: params } )
    result = app.call env
    body = result[2][0]
    body.should == IO.binread('/Users/alistaircockburn/Desktop/2x2.png')
  end




  #===============================
  def dont_test_02_can_upload_binary_value_via_rack
    #this is still a nul test, doesn't actually test anything about uploads
    puts "\n...starting test_02_can_upload_binary_value_via_rack"

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

    app = Z_rack_test_app.new
    params = {
        "Upload" => "Upload",
        "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
        "CONTENT_LENGTH" => input.size,
        :input => input
    }
    # env = alistairs_env_for( '/', { params: params } )
    # puts
    # puts "env 0 = " + env.inspect
    # puts

    env = alistairs_env_for( '/',
                                     "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                     "CONTENT_LENGTH" => input.size,
                                     :input => input
    )
    puts
    puts "env 1 = " + env.inspect
    puts


    env = Rack::MockRequest.env_for("/",
                                  "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                  "CONTENT_LENGTH" => input.size,
                                  :input => input
    )

    req = Rack::Request.new env
    puts
    puts "env 2 = " + env.inspect
    puts


  puts "first req: " + req.inspect
  puts "first req.POST: " + req.POST.inspect
#    req.POST.should =~ "fileupload"
#    req.POST.should.include "reply"
  req.content_length== input.size
  req.media_type== 'multipart/form-data'
  req.media_type_params['boundary']== 'AaB03x'
  req.POST["reply"]== "yes"
  f = req.POST["fileupload"]
  f[:type]== "image/jpeg"
  f[:filename]== "dj.jpg"
  f[:tempfile].size.should== 76
# req.should.be.form_data
 req.content_length.should== input.size
 req.media_type.should== 'multipart/form-data'
# req.media_type_params.should.include 'boundary'
 req.media_type_params['boundary'].should== 'AaB03x'
 req.POST["reply"].should== "yes"
# f.should.be.kind_of Hash
# f.should.include :tempfile

  # result = request_via_API( app,
  #                             "POST",
  #                             '/ignored',
  #                              "Upload"=>"Upload",
  #                              "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
  #                              "CONTENT_LENGTH" => input.size,
  #                              :input => input)

    result = app.call env
    puts
    puts "Received result:#{result.inspect}"


    exp = {
      out_action: "GET_named_page",
    }
    exp.should == exp

    puts "test_05_can_upload_file done"
  end

end
