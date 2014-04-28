# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends

require 'rack'
require 'erb'
require 'sinatra'
require 'erubis'

class Muffinland < Sinatra::Base
attr :path, :params
  def call(env)
    request  = Rack::Request.new(env)
    if request.get? then
      out = handle_get(request); end
    if request.post? then
      out = handle_post(request); end
    out
  end
end

def get_erb( pathToViews, viewfilename )
  fn = pathToViews + viewfilename
  ERB.new(File.open( fn, 'r').read)
end


def handle_get( request )
  pathToViews = "../src/views/"

  params = request.params
  path = request.path

  response = Rack::Response.new
  response['Content-Type'] = 'text/html'
  response.write "it's a GET."
  response.write "\<BR\>"
  response.write "Page requested = #{path}."
  response.write "\<BR\>"
  response.write "Params = #{params}."
  response.write "\<BR\>"

#  day = "wednesday"
#  day_template = "Today is <%= day %>."
  viewfilename = "simpleGET.erb"
  fn = pathToViews + viewfilename
  eruby = Erubis::Eruby.new(File.open( fn, 'r').read)
  out = eruby.result(:path=>path, :params=>params)
  response.write out
#  erb = ERB.new(File.open( fn, 'r').read)
#  response.write erb.result


=begin
  erb = ERB.new(simple_template)
  puts output = erb.result()
#  erb = get_erb( pathToViews, "simpleGET.erb")
  viewfilename = "simpleGET.erb"
  fn = pathToViews + viewfilename
  erb = ERB.new(File.open( fn, 'r').read)
  response.write erb.result
=end

  response.write "\<BR\>"
#  response.write outFor(path, params)
  response.write "Bests. Alistair."
  response.write "\<BR\>"
  response.finish

end

def outFor(path, params)
  puts path
  case path
    when "/0"
      "0."
    when "/aaa"
      "aaa"
    else
      "whatever and :#{params}:"
  end
end




#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
  @myPosts ||= Array.new
  @myPosts.push(request)

  params = request.params
  pathinfo = request.path_info

  response = Rack::Response.new
  response['Content-Type'] = 'text/html'
  response.write "Got that POST, baby. "
  response.write "Page requested = #{pathinfo}. "
  response.write "Params = #{params}. "
  response.finish
end




