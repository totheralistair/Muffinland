# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
#
require 'rack'
require 'erb'
require 'erubis'

class Muffinland

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

#===== GETs =====
def handle_get( request )
  path = request.path
  params = request.params
  case path
    when "/post"
      get_post( path, params )
    else
      get_named_page( path, params )
  end
end

def get_post( path, params )
  post_number = @myPosts.size
  respond( "POST_numbered_input1.erb", binding() )
#  respond( "simpleDataInput.erb", binding() )
end

def get_named_page( path, params )
  page_name = path[1..path.size]
  page_number = page_name.to_i
  if page_number < @myPosts.size then
    requestedPost = @myPosts[page_number]
    inputValue = requestedPost.params["InputValue"]
    respond("GET_named_page1.erb", binding())
  else
    respond("404.erb", binding())
  end

end

def get_unknown( path, params )
  respond("404.erb", binding())
end

#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
#  @myPosts ||= Array.new
  @myPosts.push(request)
  size = @myPosts.size - 1

  path = request.path
  params = request.params
  inputValue = params["InputValue"]

  respond("simplePOST.erb", binding())
end
