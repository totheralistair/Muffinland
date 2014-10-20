require 'rack'
require_relative '../src/muffinland'
require_relative '../src/ml_request'
require_relative '../src/html_from_templatefile'

# Hex adapter to Muffinland using Rack for web-type io
# is also tied to Erubis, which may need to be changed one day

class Muffinland_via_rack

  def initialize( hex_app, viewsFolder )
    @app = hex_app
    @viewsFolder = viewsFolder
  end


  def call(env) # hooks into the Rack Request chain
    request = Ml_RackRequest.new( env ) # hide the 'Rack'ness
    mlResult = @app.handle( request )

    template_fn = @viewsFolder + mlResult[:out_action] + ".erb"
    page = htmlpage_from_templatefile( template_fn , binding )

    response = Rack::Response.new
    response.write( page )
    response.finish
  end

end

