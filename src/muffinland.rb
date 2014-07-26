# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# some changes:
# 2014-07-24 18:25 ending v0.010; working. starting v0.011, all about to become broken
# 2014-07-26 tagging hacked in; starting object model. big changes ahead.
# 2014-07-26 taggin taken out, domain model put in.

require 'rack'
require 'erb'
require 'erubis'
require 'logger'

#===== These i/o utilities should be in a shared place one day =====
def emit_response_using_template( templateFullFn, binding)
  response = Rack::Response.new
  response.write  page_from_template( templateFullFn, binding )
  response.finish
end

def page_from_template( templateFullFn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( templateFullFn, 'r').read)
  pageTemplate.result(binding)
end


#=====
class Muffinland
  # Muffinland know global policies and environmental
  # details, not histories and private things.

  def initialize(viewsFolder)
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins

    @viewsFolder = viewsFolder    # I could hope this goes away one day, ugh.

    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def call(env) #this is the Rack Request chain that kicks everything off
    request  = Rack::Request.new(env)
    case
      when request.get? then handle_get(request)
      when request.post? then handle_post(request)
      when request.path=="/post" then handle_post(request)
    end
  end
end

#===== This utility belongs here =====
def respond( templateJustFn, binding)
  emit_response_using_template( @viewsFolder + templateJustFn, binding )
end

#===== GETs =====
def handle_get( request )

  muffin_name, muffin_number = @theHistorian.requested_nameAndNumber_from( request )

  case
    when @theHistorian.no_history_to_report
      show_404_on_EmptyDB
    when @theBaker.isa_registered_muffin( muffin_number)
      show_muffin_numbered( muffin_number )
    else
      show_404_basic( request, muffin_name )
  end

end

def show_404_on_EmptyDB
  respond("404_on_EmptyDB.erb", binding( ) )
end

def show_404_basic( request, muffin_name )
  show = {
      :requested_name => muffin_name,
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|req.params["MuffinContents"]}
  }
  respond("404.erb", binding( ) )
end

def show_muffin_numbered( muffin_number )
  show = {
      :muffin_number => muffin_number,
      :muffin_body => @theBaker.raw_number( muffin_number ),
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|req.params["MuffinContents"]}
  }
  respond("GET_named_page.erb", binding())
end


#===================================================
def handle_post( request ) # expect Rack::Request, emit Rack::Response
  @theHistorian.add_request( request )
  @log.info("Just received POST:" + request.env.inspect)
  params = request.params
  case   # dangerous: button names are in the Requests as commands!
    when params.has_key?("Go")
      handle_add_new_muffin(request)
=begin
    when params.has_key?("Change")
      handle_change_muffin(request)
    when params.has_key?("Tag")
      handle_tag_muffin(request)
=end
    else
      print "DOIN NUTHNG"
  end
end

def handle_add_new_muffin( request ) # expect Rack::Request, emit Rack::Response
  muffin_number = @theBaker.add_new_muffin(request)
  @log.info("Added post:" + request.env.inspect)
  show_muffin_numbered( muffin_number )
end

=begin
def handle_change_muffin( request ) # expect Rack::Request, emit Rack::Response
  @log.info("Received change request with details:" + request.env.inspect)
  muffin_number = change_muffin( request )
  show_muffin_numbered( muffin_number )
end

def change_muffin( request ) # expect Rack::Request, return muffin number
  muffin_number = request.params["MuffinNumber"].to_i
  request.env["muffinNumber"] = muffin_number.to_s  # explicitly add muffinNumber to the defining request
  @myMuffins[muffin_number] = @myPosts.size  # @myMuffins indicates which @myPost entry is its defn
  @myPosts.push(request)          # @myPosts holds the actual definition
  return muffin_number
end

def handle_tag_muffin( request ) # expect Rack::Request, emit Rack::Response
  muffin_number = tag_muffin( request )
  @log.info("Received tag request with details:" + request.env.inspect)
  show_muffin_numbered( muffin_number )
end

def tag_muffin( request ) # expect Rack::Request, return muffin number
  muffin_number = request.params["MuffinNumber"].to_i
  collector_number = request.params["CollectorNumber"].to_i
  request.env["muffinNumber"] = muffin_number.to_s  # explicitly add muffinNumber to the defining request
  request.env["collectorNumber"] = collector_number.to_s  # THIS IS SILLY. STOP IT.
  @myMuffins[muffin_number] = @myPosts.size  # @myMuffins indicates which @myPost entry is its defn
  @myPosts.push(request)          # @myPosts holds the actual definition
  return muffin_number
end

def muffin_number( request )
  request.env["muffinNumber"].to_i
end

def request_is_tagged_to_collector( request, collector_number )
  request.env.has_key?( "collectorNumber" ) &&
      request.env["collectorNumber"].to_i == collector_number
end

def collectors_of( muffin_number ) # return (possibly empty) array of collector numbers
  collecting_requests = @myPosts.select{ | request |
    request.env.has_key?( "collectorNumber" )
  }
  tag_requests = collecting_requests.select{ | request |
    muffin_number(request) == muffin_number #This doesn't belong here like this
  }
  tag_requests.map { | request | request.env["collectorNumber"].to_i }
end
=end


#===================
class Muffin

  def initialize( number, defining_request)
    @myNumber = number
    @myRaw = defining_request.params["MuffinContents"]
  end

  def raw
    @myRaw
  end
end

#===================
class Historian # knows the history of what has happened, all Posts

  def initialize
    @thePosts = Array.new
  end

  def no_history_to_report;  @thePosts.size == 0; end

  def dangerously_all_posts; @thePosts; end #yep, dangerous. remove eventually


  def add_request( request )
    @thePosts << request
  end

  def requested_nameAndNumber_from( request )
    muffin_name = request.path[1..request.path.size]
    muffin_number = muffin_name.to_i
    muffin_number = nil if (muffin_name != muffin_number.to_s)
    return muffin_name, muffin_number
  end

end


#===================
class Baker # knows the whereabouts and handlings of muffins.

  def initialize
    @theMuffins = Array.new
  end

  def dangerously_all_muffins; @theMuffins; end #yep, dangerous. remove eventually


  def isa_registered_muffin( n )
    (n.is_a? Integer) && ( n > -1 ) && ( n < @theMuffins.size )
  end

  def raw_number( muffin_number )
    @theMuffins[muffin_number].raw
  end

  def add_new_muffin( request ) # expect Rack::Request, modify the Request, return muffin number
    muffin_number = @theMuffins.size

    request.env["muffinNumber"] = muffin_number.to_s  #  modify the defining request!!
    @theMuffins << Muffin.new( muffin_number, request )

    return muffin_number
  end

end


