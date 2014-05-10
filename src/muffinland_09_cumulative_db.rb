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

#===== These utilities should be in shared place one day =====
def page_from_template( fn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( fn, 'r').read)
  pageTemplate.result(binding)
end

def page_from_folder_template( folder, fn, binding )
  page_from_template( folder+fn, binding)
end

def respondFromFullFn( templateFullFn, binding)
  response = Rack::Response.new
  response.write  page_from_template( templateFullFn, binding )
  response.finish
end

#===== These utilities belong here =====
def respondMyFromViewsFolder( templateJustFn, binding)
  respondFromFullFn( @viewsFolder + templateJustFn, binding )
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
  respondMyFromViewsFolder( "POST_ask_for_input_01.erb", binding() )
end

def get_named_page( path, params )
  muffin_name = path[1..path.size]
  muffin_number = muffin_name.to_i
  if muffin_number < @myPosts.size then
    requestedPost = @myPosts[muffin_number]
    muffin_contents = requestedPost.params["InputValue"]
    respondMyFromViewsFolder("GET_named_page_01.erb", binding())
  else
    respondMyFromViewsFolder("404_v01.erb", binding())
  end

end

def get_unknown( path, params )
  respondMyFromViewsFolder("404_v01.erb", binding())
end

#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
#  @myPosts ||= Array.new
  @myPosts.push(request)
  targetLocation = @myPosts.size - 1

  path = request.path
  params = request.params
  inputValue = params["InputValue"]

  respondMyFromViewsFolder("POST_respond_to_input_01.erb", binding())
end
