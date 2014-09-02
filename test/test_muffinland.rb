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
  request = Ml_RackRequest.new( rr )
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
    t0=Time.now.to_f

    app = Muffinland.new

    mlResponse = request_via_API( app, "GET", '/' )
    exp = {out_action:  "EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/aaa' )
    exp =  {out_action:  "EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_00_emptyDB done. #{((t1-t0)*1000).round(2)}"
  end


#=================================================
  def test_01_posts_return_contents
    puts "test_01_posts starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    mlResponse = request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        dangerously_all_muffins_for_viewing:   ["a"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    exp = {
    out_action:   "GET_named_page",
    muffin_id:   1,
    dangerously_all_muffins_for_viewing:   ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_01_posts done. #{((t1-t0)*1000).round(2)}"
  end


#=================================================
  def test_02_can_post_and_get_even_404
    puts "test_02_postAndGet starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"c" } )
    mlResponse = request_via_API( app, "GET", '/1' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body:   "b",
        dangerously_all_muffins_for_viewing:   ["a", "b", "c"]
    }
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/77' )
    exp = {
        out_action:   "404",
        muffin_id:   nil,
        muffin_body:   nil,
        dangerously_all_muffins_for_viewing:   ["a", "b", "c"]
    }
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_02_postAndGet done. #{((t1-t0)*1000).round(2)}"
  end

#=================================================
  def test_03_can_change_a_muffin
    puts "test_03_can_change_a_muffin starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    test_image = "/Users/alistaircockburn/Desktop/2x2.png"
    file = Rack::Test::UploadedFile.new(test_image, "image/png")

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    mlResponse = request_via_API( app, "POST", '/ignored',{ "Change"=>"Change", "MuffinNumber"=> "0", "MuffinContents"=>"b" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body:   "b",
        dangerously_all_muffins_for_viewing:   ["b"]
    }
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_03_can_change_a_muffin done. #{((t1-t0)*1000).round(2)}"
  end


#=================================================
  def test_04_can_tag_a_muffin_to_another
    puts "test_04_can_tag_a_muffin_to_another starting..."
    t0=Time.now.to_f

    app = Muffinland.new

    mlResponse = request_via_API( app, "POST", '/ignored',{
        "Add"=>"Add", "MuffinContents"=>"a" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body:   "a",
        muffin_is_collection:   false,
        muffin_collects:   Array.new,
        belongs_to_ids:   Array.new,
        all_collections_just_ids:   Array.new,
        dangerously_all_muffins_for_viewing:   ["a"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "POST", '/ignored',{
        "Add"=>"Add", "MuffinContents"=>"b" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body:   "b",
        muffin_is_collection:   false,
        muffin_collects:   Array.new,
        belongs_to_ids:   Array.new,
        all_collections_just_ids:   Array.new,
        dangerously_all_muffins_for_viewing:   ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "POST", '/ignored',{
        "Make Collection"=>"Make Collection", "MuffinNumber"=> "1" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body:   "b",
        muffin_is_collection:   true,
        muffin_collects:   Array.new,
        belongs_to_ids:   Array.new,
        all_collections_just_ids:   [1],
        dangerously_all_muffins_for_viewing:   ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "POST", '/ignored',{
        "Tag"=>"Tag", "MuffinNumber"=> "0", "CollectorNumber"=>"1" } )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0,
        muffin_body:   "a",
        muffin_is_collection:   false,
        muffin_collects:   Array.new,
        belongs_to_ids:   [1]  ,
        all_collections_just_ids:   [1]  ,
        dangerously_all_muffins_for_viewing:   ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp


    mlResponse = request_via_API( app, "GET", '/1' )
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1,
        muffin_body:   "b",
        muffin_is_collection:   true,
        muffin_collects:   [0],
        belongs_to_ids:    Array.new ,
        all_collections_just_ids:   [1]  ,
        dangerously_all_muffins_for_viewing:   ["a", "b"]
    }
    mlResponse.extract_per( exp ).should == exp


    t1=Time.now.to_f
    puts "test_04_can_tag_a_muffin_to_another done. #{((t1-t0)*1000).round(2)}"
  end


  #=================================================
  def test_05_can_upload_a_file
    puts "test_05_can_upload_a_file starting..."
    t0=Time.now.to_f
    app = Muffinland.new

    fn0 = "/Users/alistaircockburn/Desktop/Enviado desde mi iPad.txt"
    params = {
        "Upload" => "Upload",
        description: 'A text file',
        text_source: Rack::Multipart::UploadedFile.new( fn0 )
    }
    mlResponse = request_via_API( app, "POST", '/ignored', params )
    file_contents_0 = File.read(fn0)
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   0 ,
        muffin_body:   file_contents_0 ,
        dangerously_all_muffins_for_viewing:   [file_contents_0]
    }
    mlResponse.extract_per( exp ).should == exp

    fn1 = "/Users/alistaircockburn/Desktop/2x2.png"
    params = {
        "Upload" => "Upload",
        description: 'A binary file',
        text_source: Rack::Multipart::UploadedFile.new( fn1, "image/png", binary=true )
    }
    mlResponse = request_via_API( app, "POST", '/ignored', params )
    file_contents_1 = IO.binread('/Users/alistaircockburn/Desktop/2x2.png')
    html_from_binary_image_1 = '<img src="data:image/png;base64,' + Base64.encode64(file_contents_1) + '" /> '
    exp = {
        out_action:   "GET_named_page",
        muffin_id:   1 ,
        muffin_body:   html_from_binary_image_1,
        dangerously_all_muffins_for_viewing:   [file_contents_0, html_from_binary_image_1]
    }
    mlResponse.extract_per( exp ).should == exp

    t1=Time.now.to_f
    puts "test_05_can_upload_a_file done. #{((t1-t0)*1000).round(2)}"
  end


  #=================================================
  def test_06_speed_test
    puts "test_06_speed_test starting..."
    t0=Time.now.to_f
    app = Muffinland.new

    limit = 2001
      puts "#{limit} adds"
    for i in 0..limit
      request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    end

    t1=Time.now.to_f
    puts "test_06_speed_test done. #{((t1-t0)*1000).round(2)}"
  end



#=================================================


end

