# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# some changes:
# 2014-07-24 18:25 ending v0.010; working. starting v0.011, all about to become broken

require 'rack'
require 'erb'
require 'erubis'
require 'logger'

class Muffinland

  def initialize(viewsFolder)
    @myPosts = Array.new
    @myMuffins = Array.new
    @next_available_muffin_number = 0

    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
    @viewsFolder = viewsFolder
  end

  def call(env) #this is the Rack Request chain
    request  = Rack::Request.new(env)
    case
      when request.get?
        handle_get(request)
      when request.post? || request.path=="/post"
        handle_post(request)
    end
  end
end

#===== These i/o utilities should be in a shared place one day =====
def page_from_template( templateFullFn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( templateFullFn, 'r').read)
  pageTemplate.result(binding)
end

def emit_response_using_template( templateFullFn, binding)
  response = Rack::Response.new
  response.write  page_from_template( templateFullFn, binding )
  response.finish
end

#===== These utilities belong here =====
def emit_response_using_known_viewFolder( templateJustFn, binding)
  emit_response_using_template( @viewsFolder + templateJustFn, binding )
end

#===== GETs =====
def handle_get( request )
  muffin_name = request.path[1..request.path.size]
  muffin_number = muffin_name.to_i
  itsanumber = (muffin_name == muffin_number.to_s)

  case
    when @myPosts.size == 0
      emit_response_using_known_viewFolder("404_on_EmptyDB.erb", binding( ) )
    when itsanumber && muffin_number < @myPosts.size
      show_muffin_numbered( muffin_number, request )
    else
      emit_response_using_known_viewFolder("404.erb", binding())
  end
end

def show_muffin_numbered( muffin_number, request )
  muffin = @myPosts[muffin_number]
  muffin_contents = muffin.params["MuffinContents"]
  emit_response_using_known_viewFolder("GET_named_page.erb", binding())
end


#===================================================
def handle_post( request ) # expect Rack::Request, emit Rack::Response
  handle_add_new_muffin(request)
end

def handle_add_new_muffin( request ) # expect Rack::Request, emit Rack::Response
  muffin_number = add_new_muffin(request)
  show_muffin_numbered( muffin_number, request )
end

def add_new_muffin( request ) # expect Rack::Request
  @log.info("Received post request with details:" + request.env.inspect)

  muffin_number = @next_available_muffin_number
  request.env["muffinNumber"] = muffin_number.to_s
  @myPosts.push(request)
  @next_available_muffin_number += 1
  return muffin_number
end

