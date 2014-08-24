require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'
#include Rack::Test::Methods

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
  env = Rack::MockRequest.env_for(path, {:method => method, :params=>params, } )
  request = Ml_RackRequest.new(
      Rack::Request.new(env) )
  app.handle request                               #this goes straight to the app API
end


def request_via_rack_without_server( app, method, path, params={} ) # app should be Muffinland_via_rack
  request = Rack::MockRequest.new(app)
  request.request(method, path, {:params=>params}) #this sends the request through the Rack call(env) chain
end


=begin
#deprecated because don't really need mlRequest_simple once I understand Rack better.
def request_via_API_w_requestSimple_deprecated( app, method, path, params={} ) # app should be Muffinland (hexagon API)
  request = Ml_request_simple.build( method, path, params )
  app.handle request
end
=end



class TestRequests < Test::Unit::TestCase
#=================================================
  def test_00_emptyDB_is_special_case
    puts "starting test_00_emptyDB"
    app = Muffinland.new

    mlResponse = request_via_API( app, "GET", '/' )
    exp = {:out_action=>"EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    mlResponse = request_via_API( app, "GET", '/aaa' )
    exp =  {:out_action=>"EmptyDB"}
    mlResponse.extract_per( exp ).should == exp

    puts "done test_00_emptyDB"
  end


#=================================================
  def test_01_posts_return_contents
    puts "starting test_01_posts"
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

    puts "done test_01_posts"
  end


#=================================================
  def test_02_can_post_and_get_even_404
    puts "starting test_02_postAndGet"
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

    puts "done test_02_postAndGet"
  end

#=================================================
  def test_03_can_change_a_muffin
    puts "starting test_03_can_change_a_muffin"
    app = Muffinland.new

    request_via_API( app, "POST", '/ignored',{ "Add"=>"Add", "MuffinContents"=>"a" } )
    mlResponse = request_via_API( app, "POST", '/ignored',{ "Change"=>"Change", "MuffinNumber"=> "0", "MuffinContents"=>"b" } )
    exp = {
        :out_action=> "GET_named_page",
        :muffin_id => 0,
        :muffin_body => "b",
        :dangerously_all_muffins_raw => ["b"]
    }
    mlResponse.extract_per( exp ).should == exp

    puts "done test_03_can_change_a_muffin"
  end


#=================================================
  def test_04_can_tag_a_muffin_to_another
    puts "starting test_04_can_tag_a_muffin_to_another"
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

    puts "done test_04_can_tag_a_muffin_to_another"
  end

#=================================================
# for test binary upload. here's the contents of 4x4.png
#  "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x04\x00\x00\x00\x04\b\x06\x00\x00\x00\xA9\xF1\x9E~\x00\x00\x00AIDAT\b\x1Dc\xFC\xF7k\xE6\x7F\x06(x\xFB\xFE3\x03\x13\x8Cs\xE2\xF4]\x06K\x9B.\x06\x86sg\xAA\xFF\xC7\xC6X\xFEgcc\xFB?{\xF6\xEC\xFF\fll\xAC\xFF\xAB\xAB+\xFF?\x7F\xFE\xFC?\b\x00\x006s\x1D\xE6\xA6\xDB\f]\x00\x00\x00\x00IEND\xAEB`\x82"

end

