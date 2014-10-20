require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
#Test::Unit::TestCase.include RSpec::Matchers

require_relative '../src/muffinland.rb'
require_relative '../src/muffinland_via_rack.rb'
require_relative '../src/ml_request.rb'
require_relative '../test/utilities_for_tests'


class TestRequests < Test::Unit::TestCase
  attr_accessor :app
  attr_accessor :start_time, :in_method
  def start which_method
    @start_time = mark
    @in_method = which_method
    p "#{in_method}"
  end
  def done ;  p "#{in_method} done in #{dt}ms" ;  end
  def mark ;  Time.now.to_f ;   end
  def dt ; (( mark - start_time) * 1000 ).round(2) ;  end



  #=================================================
  def test_z_runs_via_Rack_adapter # just check hexagon integrity, not a data check
    start __method__
    viewsFolder = "../src/views/"
    @app = Muffinland_via_rack.new(viewsFolder)

    request_via_rack_adapter_without_server( app, "GET", '/a?b=c', "d=e").body.
        should == page_from_template( viewsFolder + "EmptyDB.erb" , binding )
    done
  end



  #=================================================
  def test_00_emptyDB_is_special_case
    start __method__
    @app = Muffinland.new

    sending_expect "GET", '/aaa', {} ,
                   {
                       out_action:  "EmptyDB"
                   }

    done
  end


#=================================================
  def test_01_gets_and_posts_return_contents_incl_404
    start __method__
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

    done
  end



#=================================================
  def test_03_can_change_a_muffin
    start __method__
    @app = Muffinland.new

    just_send( "POST", '/ignored', { "Add"=>"Add", "MuffinContents"=>"a" } )

    sending_expect "POST", '/ignored',{ "Change"=>"Change", "MuffinNumber"=> "0", "MuffinContents"=>"b" } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body:   "b",
                       dangerously_all_muffins_for_viewing:   ["b"]
                   }

    done
  end


#=================================================
  def test_04_can_tag_a_muffin_to_another
    start __method__
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

    done
  end


  #=================================================
  def test_05_can_upload_a_file
    start __method__
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

    done
  end


  #=================================================
  def test_06_speed_test
    start __method__
    @app = Muffinland.new

    limit = 1
    puts "Running timing for #{limit} adds"
    for i in 0..limit
      just_send "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" }
    end

    done
  end


  #=================================================
  def test_07_can_reload_history_from_array_and_continue
    start __method__
    @app = Muffinland.new #( Nul_persister.new )

    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    app.dangerously_restart_with_history [ r0 ]

    r1 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"banaba" })
    app.handle r1

    app.dangerously_all_posts.should == [ r0, r1 ]

    done
  end


  def test_04_can_run_history_to_from_strings_and_files
    start __method__

    @app = Muffinland.new #( Nul_persister.new )

    # pre-test: make sure can serialize and reconstitute okay
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"apple" })
    r0.to_yaml.should == Ml_RackRequest::from_yaml( r0.to_yaml ).to_yaml

    # 1st, fake a history in a file:
    r0 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"less chickens" })
    array_out_to_file( [ r0.to_yaml ], history_in_file='mlhistory.txt' )

    # see if that reads OK:
    requests = requests_from_yaml_stream2( File.open( history_in_file) )
    app.dangerously_restart_with_history requests
    sending_expect "GET", '/0', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   0,
                       muffin_body: "less chickens"
                   }

    # then add to the history in the ordinary way
    sending_expect 'POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"more chickens" } ,
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body: "more chickens"
                   }

    yamld_history = yaml_my app.dangerously_all_posts     # notice I didn't check it yet. lazy

    # finally, add to the history using faked-up string / StringIO, see if that works:
    r2 = new_ml_request('POST', '/ignored',{ "Add"=>"Add", "MuffinContents"=>"end of chickens" })
    history_in_string = array_out_to_string ( yamld_history << r2.to_yaml )

    requests = requests_from_yaml_stream2( StringIO.new( history_in_string) )
    app.dangerously_restart_with_history requests

    sending_expect "GET", '/1', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   1,
                       muffin_body: "more chickens"
                   }

    sending_expect "GET", '/2', {},
                   {
                       out_action:   "GET_named_page",
                       muffin_id:   2,
                       muffin_body: "end of chickens"
                   }

    sending_expect "GET", '/3', {},
                   {
                       out_action:   "404"
                   }
    # if that all works, loading/unloading/faking history w arrays/strings/files all work :-)

    done
  end





#=================================================


end

