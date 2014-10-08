require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
Test::Unit::TestCase.include RSpec::Matchers

require_relative '../src/muffinland.rb'
require_relative '../src/ml_request.rb'

class Hash
def extract_per( sampleHash )
# {:a=>1, :b=>2, :c=>3}.extract_per({:b=y, :c=>z}) returns {:b=>2, :c=>3}
    sampleHash.inject({}) { |subset, (k,v) | subset[k] = self[k] ; subset }
  end
end


class TestRequests < Test::Unit::TestCase
  attr_accessor :app

#=== utilities ======================
  def mark
    Time.now.to_f
  end

  def dt_now t0
    (( mark - t0) * 1000 ).round(2)
  end

  def new_ml_request method, path, params={}
    Ml_RackRequest.new(
        Rack::Request.new(
            Rack::MockRequest.env_for( path, {:method => method, :params=>params} )
        )
    )
  end

  def just_send method, path, params
    app.handle new_ml_request( method, path, params )
  end

  def send_receive method, path, params   # same but for different reading
    app.handle new_ml_request( method, path, params )
  end

  def sending_expect method, path, params, expectedResult
    (send_receive( method, path, params ) ).
        should include expectedResult
  end

  def request_via_API( app, method, path, params={} ) # app should be Muffinland (hexagon API)
    rr = Rack::Request.new( Rack::MockRequest.env_for(path, {:method => method, :params=>params}  ) )
    app.handle Ml_RackRequest.new( rr )
  end


  def request_via_rack_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
    request = Rack::MockRequest.new(app)
    request.request(method, path, {:params=>params}) #this sends the request through the Rack call(env) chain
  end



  #=================================================
  def test_00_emptyDB_is_special_case
    puts "test_00_emptyDB starting..."
    t0 = mark

    @app = Muffinland.new

    sending_expect "GET", '/aaa', {} ,
                   {
                       out_action:  "EmptyDB"
                   }

    puts "test_00_emptyDB done in #{dt_now(t0)}"
  end


#=================================================
  def test_01_gets_and_posts_return_contents_incl_404
    puts "test_01_posts starting..."
    t0 = mark

    @app = Muffinland.new

    sending_expect "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" },
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body: "a",
                       dangerously_all_muffins_for_viewing:   ["a"]
                   }

    sending_expect "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" },
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body: "b",
                       dangerously_all_muffins_for_viewing:   ["a", "b"]
                   }
    sending_expect "GET", '/0', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body: "a"
                   }

    sending_expect "GET", '/1', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body: "b"
                   }

    sending_expect "GET", '/2', {},
                   {
                       out_action:   "404"
                   }

    puts "test_01_posts done in #{dt_now(t0)}"
  end



#=================================================
  def test_03_can_change_a_muffin
    puts "test_03_can_change_a_muffin starting..."
    t0 = mark

    @app = Muffinland.new

    just_send( "POST", '/ignored', { "Add"=>"Add", "MuffinContents"=>"a" } )

    sending_expect "POST", '/ignored',{ "Change"=>"Change", "MuffinNumber"=> "0", "MuffinContents"=>"b" } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body:   "b",
                       dangerously_all_muffins_for_viewing:   ["b"]
                   }

    puts "test_03_can_change_a_muffin done in #{dt_now(t0)}"
  end


#=================================================
  def test_04_can_tag_a_muffin_to_another
    puts "test_04_can_tag_a_muffin_to_another starting..."
    t0 = mark

    @app = Muffinland.new

    just_send  "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" }
    just_send  "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" }

    sending_expect "POST", '/ignored',{ "Make Collection"=>"Make Collection", "MuffinNumber"=> "1" } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body:   "b",
                       muffin_is_collection:   true,
                       muffin_collects:   Array.new,
                       belongs_to_ids:   Array.new,
                       all_collections_just_ids:   [1],
                       dangerously_all_muffins_for_viewing:   ["a", "b"]
                   }

    sending_expect "POST", '/ignored',{ "Tag"=>"Tag", "MuffinNumber"=> "0", "CollectorNumber"=>"1" } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body:   "a",
                       muffin_is_collection:   false,
                       muffin_collects:   Array.new,
                       belongs_to_ids:   [1]  ,
                       all_collections_just_ids:   [1]  ,
                       dangerously_all_muffins_for_viewing:   ["a", "b"]
                   }

    sending_expect  "GET", '/1', {} ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body:   "b",
                       muffin_is_collection:   true,
                       muffin_collects:   [0],
                       belongs_to_ids:    Array.new ,
                       all_collections_just_ids:   [1]  ,
                       dangerously_all_muffins_for_viewing:   ["a", "b"]
                   }

    puts "test_04_can_tag_a_muffin_to_another done in #{dt_now(t0)}"
  end


  #=================================================
  def test_05_can_upload_a_file
    puts "test_05_can_upload_a_file starting..."
    t0 = mark

    @app = Muffinland.new

    fn0 = "/Users/alistaircockburn/Desktop/Enviado desde mi iPad.txt"
    file_contents_0 = File.read(fn0)

    fn1 = "/Users/alistaircockburn/Desktop/2x2.png"
    file_contents_1 = IO.binread('/Users/alistaircockburn/Desktop/2x2.png')
    html_from_binary_file_1 = '<img src="data:image/png;base64,' + Base64.encode64(file_contents_1) + '" /> '

    sending_expect "POST", '/ignored',
        {
          "Upload" => "Upload",
          description: 'A text file',
          text_source: Rack::Multipart::UploadedFile.new( fn0 )
        } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0 ,
                       muffin_body:   file_contents_0 ,
                       dangerously_all_muffins_for_viewing:   [file_contents_0]
                   }

    sending_expect "POST", '/ignored', {
        "Upload" => "Upload",
        description: 'A binary file',
        text_source: Rack::Multipart::UploadedFile.new( fn1, "image/png", binary=true )
        } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1 ,
                       muffin_body:   html_from_binary_file_1,
                       dangerously_all_muffins_for_viewing:   [file_contents_0, html_from_binary_file_1]
                   }

    puts "test_05_can_upload_a_file done in #{dt_now(t0)}"
  end


  #=================================================
  def test_06_speed_test
    puts "test_06_speed_test starting..."
    t0 = mark

    @app = Muffinland.new

    limit = 1
      puts "Running timing for #{limit} adds"
    for i in 0..limit
      just_send "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" }
    end

    puts "test_06_speed_test done in #{dt_now(t0)}"
  end



#=================================================


end

