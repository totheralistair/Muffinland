require 'rack/test'
require 'rspec/expectations'
require 'test/unit'
require 'erubis'

require_relative '../src/muffinland_10_cumulative_db.rb'

class TestRequests < Test::Unit::TestCase
  include Rack::Test::Methods

  def run_without_server(app, method, route, params={})    # parameterized for GETs and POSTs
    aRequest = Rack::MockRequest.new(app)
    aRequest.request(method, route, {:params=>params})
  end


#=================================================
  def test_00_emptyDB_404
    puts "test_00_emptyDB_404"
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)

    path, params = '/', '{}'
    next_available_muffin_number = 0
    exp = page_from_template( viewsFolder + "404_v10.erb", binding() )
    got = run_without_server( app, "GET", '/').body
    got.should == exp

    path, params = '/aaa', '{}'
    next_available_muffin_number = 0
    exp = page_from_template( viewsFolder + "404_v10.erb", binding() )
    got = run_without_server( app, "GET", '/aaa').body
    got.should == exp
  end

  def test_01_posts
    puts "test_01_posts"
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)

    path, params = '/ignored', '{"InputValue"=>"test1"}'
    muffin_number, muffin_contents = 0, 'test1'
    next_available_muffin_number = 1
    exp = page_from_template( viewsFolder + "GET_named_page_10.erb", binding() )
    got = run_without_server( app, "POST", '/ignored',"InputValue"=>"test1").body    # 'login=WoW').body
    got.should == exp

    path, params = '/stillignored', '{"InputValue"=>"test2"}'
    muffin_number, muffin_contents = 1, 'test2'
    next_available_muffin_number = 2
    exp = page_from_template( viewsFolder + "GET_named_page_10.erb", binding() )
    got = run_without_server( app, "POST", '/stillignored',"InputValue"=>"test2").body    # 'login=WoW').body
    got.should == exp
  end


  def test_02_postAndGet
    puts "test_02_postAndGet"
    viewsFolder = "../src/views/"
    app = Muffinland.new(viewsFolder)

    path, params = '/ignored', '{"InputValue"=>"test1"}'
    muffin_number, muffin_contents = 0, 'test1'
    next_available_muffin_number = 1
    exp = page_from_template( viewsFolder + "GET_named_page_10.erb", binding() )
    got = run_without_server( app, "POST", '/ignored',"InputValue"=>"test1").body    # 'login=WoW').body
    got.should == exp

    path, params = '/stillignored', '{"InputValue"=>"test2"}'
    muffin_number, muffin_contents = 1, 'test2'
    next_available_muffin_number = 2
    exp = page_from_template( viewsFolder + "GET_named_page_10.erb", binding() )
    got = run_without_server( app, "POST", '/stillignored',"InputValue"=>"test2").body    # 'login=WoW').body
    got.should == exp

    path, params = '/1', '{}'
    muffin_number, muffin_contents  = 1, 'test2'
    next_available_muffin_number = 2
    exp = page_from_template( viewsFolder + "GET_named_page_10.erb", binding() )
    got = run_without_server( app, "GET", '/1').body    # 'login=WoW').body
    got.should == exp

    path, params = '/0', '{}'
    muffin_number, muffin_contents  = 0, 'test1'
    next_available_muffin_number = 2
    exp = page_from_template( viewsFolder + "GET_named_page_10.erb", binding() )
    got = run_without_server( app, "GET", '/0').body    # 'login=WoW').body
    got.should == exp

    path, params = '/3', '{}'
    muffin_number, muffin_contents  = 3, 'should produce a 404'
    next_available_muffin_number = 2
    exp = page_from_template( viewsFolder + "404_v10.erb", binding() )
    got = run_without_server( app, "GET", '/3').body    # 'login=WoW').body
    got.should == exp

  end
end

