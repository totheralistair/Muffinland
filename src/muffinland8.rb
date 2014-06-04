# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
#
require 'rack'
require 'erb'
require 'erubis'

class Muffinland
  attr :viewsFolder

  def initialize(viewsFolder)
    @viewsFolder = viewsFolder
    @myPosts = Array.new
  end

  def call(env)
    request  = Rack::Request.new(env)
    if request.get? then out = handle_get(request); end
    if request.post? then out = handle_post(request); end
    out
  end
end

#===== utilities =====
def page_from_template( fn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( fn, 'r').read)
  pageTemplate.result(binding)
end

def respond( templateFn, binding)
  response = Rack::Response.new
  response.write  page_from_template( @viewsFolder + templateFn, binding )
  response.finish
end

def post_contents( request )
  puts request.body
  request.body
end

#===== GETs =====
def handle_get( request )
  path = request.path
  params = request.params
  case path
    when "/post"
      get_post( path, params )
    when "/0"
      get_0( path, params )
    else
      get_others( path, params )
  end
end

def get_post( path, params )
  respond( "simpleDataInput.erb", binding() )
end

def get_0( path, params )
  requestedPost = @myPosts[0]
  inputValue = requestedPost.params["InputValue"]

  respond( "GET_0.erb", binding() )
end

def get_others( path, params )
  respond("simpleGET.erb", binding())
end

#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
#  @myPosts ||= Array.new
  @myPosts.push(request)
  size = @myPosts.size

  path = request.path
  params = request.params
  inputValue = params["InputValue"]

  respond("simplePOST.erb", binding())
end
