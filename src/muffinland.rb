# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
#
require 'rack'
require 'erb'
require 'erubis'
require 'logger'

class Muffinland

  def initialize(viewsFolder)
    @viewsFolder = viewsFolder
    @myPosts = Array.new

    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def next_available_muffin_number
    @myPosts.size
  end

  def call(env)
    request  = Rack::Request.new(env)
    if request.get? then out = handle_get(request); end
    if request.post? then out = handle_post(request); end
    out
  end
end

#===== These utilities should be in shared place one day =====
def page_from_folder_fn_template( folder, fn, binding )
  page_from_template( folder+fn, binding)
end

def response_using_template( templateFullFn, binding)
  response = Rack::Response.new
  response.write  page_from_template( templateFullFn, binding )
  response.finish
end

def page_from_template( templateFullFn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( templateFullFn, 'r').read)
  pageTemplate.result(binding)
end

#===== These utilities belong here =====
def response_using_view_folder( templateJustFn, binding)
  response_using_template( @viewsFolder + templateJustFn, binding )
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

def get_named_page( path, params )
  muffin_name = path[1..path.size]
  muffin_number = muffin_name.to_i
  itsanumber = (muffin_name == muffin_number.to_s)

  case
    when @myPosts.size == 0
      response_using_view_folder("404_on_EmptyDB.erb", binding( ) )
    when itsanumber && muffin_number < @myPosts.size
      show_muffin_numbered( muffin_number, path, params )
    else
      get_unknown( path, params )
  end
end

def show_muffin_numbered( muffin_number, path, params )
  muffin = @myPosts[muffin_number]
  muffin_contents = muffin.params["InputValue"]
  response_using_view_folder("GET_named_page.erb", binding())
end


def get_unknown( path, params )
  response_using_view_folder("404.erb", binding())
end

#===================================================
def handle_post( request ) # expect Rack::Request, return Rack::Response
  @myPosts.push(request)

  muffin_number = @myPosts.size - 1
  @log.info("post request details:" + request.env.inspect)
  path = request.path
  params = request.params
  show_muffin_numbered( muffin_number, path, params )
end
