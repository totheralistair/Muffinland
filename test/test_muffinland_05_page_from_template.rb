require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'

require_relative '../src/muffinland_05_page_from_template.rb'

class TestRequests < Test::Unit::TestCase
  include Rack::Test::Methods

  def run_without_server(app, method, route, params={})    # parameterized for GETs and POSTs
    aRequest = Rack::MockRequest.new(app)
    aRequest.request(method, route, {:params=>params})
  end


#=================================================
  def test_00_get_without_server
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)
    path = '/a'
    params = '{"d"=>"e", "b"=>"c"}'

    dynamic_page = page_from_template( viewsFolder + "view_05_simpleGET.erb" )
    exp = dynamic_page.result(binding())
    got = run_without_server( app, "GET", '/a?b=c', "d=e").body
    got.should == exp
  end

  def test_01_post_without_server
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)
    path = '/login'
    params = '{"login"=>"Wow"}' #'{"login"=>"Wow"}'

    dynamic_page = page_from_template( viewsFolder + "view_05_data_input_response.erb" )
    exp = dynamic_page.result(binding())
    got = run_without_server( app, "POST", '/login',{"login"=>"Wow"}).body    # 'login=WoW').body
    got.should == exp
  end

end

