require 'rack/test'
require 'rspec/expectations'
require 'test/unit'

require_relative '../src/muffinland.rb'

class TestRequests < Test::Unit::TestCase
  include Rack::Test::Methods

  def run_without_server(app, method, route, params={})    # parameterized for GETs and POSTs
    aRequest = Rack::MockRequest.new(app)
    aRequest.request(method, route, {:params=>params})
  end

  def run_with_server(app, method, route, params={})      # still only GETs
    aSession = Rack::Test::Session.new(app)
    aSession.request route, {:method=>method}.merge(:params=>params)
  end

# p.s. I don't understand the difference above between MockRequest and Session

#=================================================
  def test_00_get_without_server
    app = Muffinland.new
    run_without_server( app, "POST", '/ook', "postKey=postValue" ).body.should ==
        "Got that POST, baby. Page requested = /ook. Params = {\"postKey\"=>\"postValue\"}. "
    run_without_server( app, "GET", '/blarg?A=aa&B=bb', "getKey=getValue").body.should ==
        "Nice GET there. Page requested = /blarg. Params = {\"getKey\"=>\"getValue\", \"A\"=>\"aa\", \"B\"=>\"bb\"}. Bests. Alistair."
    run_without_server( app, "GET", '/helloalistair').body.should ==
        "hello, Alistair"
    run_without_server( app, "GET", '/0').body.should ==
        "should be 0, Alistair"
  end

end

