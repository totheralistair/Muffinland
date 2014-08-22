require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'

require_relative '../src/muffinland.rb'
require_relative '../src/ml_request.rb'

class TestRequests < Test::Unit::TestCase

  # NOT being used currently. Was working. Shifting now to API tests
  # I'm leaving it in here as an example of how to do it
  include Rack::Test::Methods
  def request_via_rack_without_server( app, method, path, params={} )
  # note: app should be Muffinland_via_rack (ui adapter to visitor port on hexagon)
     rackRequest = Rack::MockRequest.new(app)
     rackRequest.request(method, path, {:params=>params})
  end


  def request_via_API( app, method, path, params={} )
    # note: app should be Muffinland directly (hexagon API)
    app.handle  Ml_request_simple.build( method, path, params )
  end


#=================================================
  def test_00_emptyDB_is_special_case
    puts "starting test_00_emptyDB"
    app = Muffinland.new

    got = request_via_API( app, "GET", '/' )
    exp = {:out_action=>"EmptyDB"}
    got.should == exp

    got = request_via_API( app, "GET", '/aaa' )
    exp =  {:out_action=>"EmptyDB"}
    got.should == exp

    puts "done test_00_emptyDB"
  end


#=================================================
  def test_01_posts_return_contents
    puts "starting test_01_posts"
    app = Muffinland.new

    mlRequest = request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    exp = {
        :outAction => "GET_named_page",
        :muffin_id => 0,
        :dangerously_all_muffins_raw => ["a"]
    }

    got = {
        :outAction=> mlRequest[:out_action],
        :muffin_id => mlRequest[:muffin_id],
        :dangerously_all_muffins_raw => mlRequest[:dangerously_all_muffins_raw]
    }

    got.should == exp

    mlRequest = request_via_API( app, "POST", '/stillignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    exp = {
    :outAction=> "GET_named_page",
    :muffin_id => 1,
    :dangerously_all_muffins_raw => ["a", "b"]
    }
    got = {
        :outAction=> mlRequest[:out_action],
        :muffin_id => mlRequest[:muffin_id],
        :dangerously_all_muffins_raw => mlRequest[:dangerously_all_muffins_raw]
    }
    got.should == exp

    puts "done test_01_posts"
  end


#=================================================
  def test_02_can_post_and_get_even_404
    puts "starting test_02_postAndGet"
    app = Muffinland.new

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"b" } )
    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"c" } )
    mlRequest = request_via_API( app, "GET", '/1' )
    exp = {
        :outAction=> "GET_named_page",
        :muffin_id => 1,
        :muffin_body => "b",
        :dangerously_all_muffins_raw => ["a", "b", "c"]
    }
    got = {
        :outAction=> mlRequest[:out_action],
        :muffin_id => mlRequest[:muffin_id],
        :muffin_body => mlRequest[:muffin_body],
        :dangerously_all_muffins_raw => mlRequest[:dangerously_all_muffins_raw]
    }
    got.should == exp

    mlRequest = request_via_API( app, "GET", '/77' )
    exp = {
        :outAction=> "404",
        :muffin_id => nil,
        :muffin_body => nil,
        :dangerously_all_muffins_raw => ["a", "b", "c"]
    }
    got = {
        :outAction=> mlRequest[:out_action],
        :muffin_id => mlRequest[:muffin_id],
        :muffin_body => mlRequest[:muffin_body],
        :dangerously_all_muffins_raw => mlRequest[:dangerously_all_muffins_raw]
    }
    got.should == exp

    puts "done test_02_postAndGet"
  end

  def test_03_can_change_a_muffin
  end

  def test_03_can_tag_a_muffin_to_another
  end

end

