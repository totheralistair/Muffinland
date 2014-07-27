# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# some changes:
# 2014-07-24 18:25 ending v0.010; working. starting v0.011, all about to become broken
# 2014-07-26 tagging hacked in; starting object model. big changes ahead.
# 2014-07-26 tagging taken out, domain model put in.
# 2014-07-27 basic tagging put back in. wanting a "request-parser" thing
# ideas: email, DTO test,

require 'rack'
require 'erb'
require 'erubis'
require 'logger'
require 'set'

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

def number_or_nil( s )
  n = s.to_i
  n = nil if (n.to_s != s)
  return n
end

def zapout( str )
  print "\n #{str} \n"
end

#=====
class Muffinland
  # Muffinland know global policies and environment, not histories and private things.

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

  muffin_name, muffin_number = @theBaker.nameAndNumber_from_path( request )
  zapout "muffin name:#{muffin_name}, muffin_number:#{muffin_number}"

  if muffin_name==""
    muffin_name = "0"
    muffin_number = 0
  end
  zapout "muffin name:#{muffin_name}, muffin_number:#{muffin_number}"

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
  reveal = {
      :requested_name => muffin_name,
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|req.params["MuffinContents"]}
  }
  respond("404.erb", binding( ) )
end

def show_muffin_numbered( muffin_number )
  reveal = {
      :muffin_number => muffin_number,
      :muffin_body => @theBaker.raw_contents( muffin_number ),
      :tags => @theBaker.muffin(muffin_number).dangerously_all_tags,
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|req.inspect}
  }
  respond("GET_named_page.erb", binding())
end


#===================================================
def handle_post( request ) # expect Rack::Request, emit Rack::Response
  @log.info("Just received POST:" + request.env.inspect)

  @theHistorian.add_request( request )

  case   # dangerous: button names are in the Requests as commands!
    when request.params.has_key?("Go")
      handle_add_new_muffin(request)
    when request.params.has_key?("Change")
      handle_change_muffin(request)
    when request.params.has_key?("Tag")
      handle_tag_muffin(request)
    else
      print "DOIN NUTHNG"
  end

end

def handle_add_new_muffin( request ) # expect Rack::Request, emit Rack::Response
  muffin_number = @theBaker.add_new_muffin(request)
  show_muffin_numbered( muffin_number )
end

def handle_change_muffin( request ) # expect Rack::Request, emit Rack::Response
  muffin_name, muffin_number = @theBaker.nameAndNumber_from_params( request )
  @theBaker.change_muffin_per_request( muffin_number, request ) ?
      show_muffin_numbered( muffin_number ) :
      show_404_basic( request, muffin_name )
end

def handle_tag_muffin( request ) # expect Rack::Request, emit Rack::Response
  muffin_name, muffin_number = @theBaker.nameAndNumber_from_params( request )
  @theBaker.tag_muffin_per_request( muffin_number, request ) ?
      show_muffin_numbered( muffin_number ) :
      show_404_basic( request, muffin_name )
end


#===================
class Muffin

  def initialize( number, defining_request)
    @myNumber = number
    @myRaw = defining_request.params["MuffinContents"]
    @myTags = Set.new
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
  end

  def raw; @myRaw; end

  def new_contents_from_request( request )
    @myRaw = request.params["MuffinContents"]
  end

  def add_tag( n ); @myTags << n; end

  def dangerously_all_tags; @myTags; end

end

#===================
class Historian # knows the history of what has happened, all Posts

  def initialize
    @thePosts = Array.new
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
  end

  def no_history_to_report;  @thePosts.size == 0; end

  def dangerously_all_posts; @thePosts; end #yep, dangerous. remove eventually


  def add_request( request )
    @thePosts << request
  end

end


#===================
class Baker # knows the whereabouts and handlings of muffins.

  def initialize
    @theMuffins = Array.new
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
  end

  def dangerously_all_muffins; @theMuffins; end #yep, dangerous. remove eventually

  def muffin(n); @theMuffins[n]; end

  def isa_registered_muffin( n )
    result = (n.is_a? Integer) && ( n > -1 ) && ( n < @theMuffins.size )
  end

  def raw_contents( muffin_number )
    @theMuffins[muffin_number].raw
  end

  def nameAndNumber_from_path( request )  # not sure this belongs here
    name = request.path[1..request.path.size]
    return name, number_or_nil(name)
  end

  def nameAndNumber_from_params( request ) # not sure this belongs here
    name = request.params["MuffinNumber"]
    number = number_or_nil(name)
    return name, number
  end

  def add_new_muffin( request ) # expect Rack::Request, modify the Request!, return muffin number
    muffin_number = @theMuffins.size

    request.env["muffinNumber"] = muffin_number.to_s  #  modify the defining request!!
    @theMuffins << Muffin.new( muffin_number, request )

        @log.info("Added post:" + request.env.inspect)
    return muffin_number
  end

  def change_muffin_per_request( muffin_number, request ) # modify the Request in place; return nil if bad muffin number
    return nil if !isa_registered_muffin( muffin_number)

    request.env["muffinNumber"] = muffin_number.to_s  #  modify the defining request!!
    @theMuffins[muffin_number].new_contents_from_request( request )

        @log.info("Changed muffin:" + request.env.inspect)
    return muffin_number
  end

  def tag_muffin_per_request( n_ignored, request ) #really want both numbers coming in here.but ok
    zapout "IN TAG"
    muffin_name = request.params["MuffinNumber"]
    muffin_number = number_or_nil( muffin_name )
    zapout "M name:#{muffin_name}, number:#{muffin_number}"
    return nil if !isa_registered_muffin( muffin_number ) #FAIL! hopefully UI will stop this

    collector_name = request.params["CollectorNumber"]
    collector_number = number_or_nil( collector_name  )
    zapout "C name:#{collector_name}, number:#{collector_number}"
    return if !isa_registered_muffin( collector_number ) #FAIL! hopefully UI will stop this

    zapout "still alive"
    request.env["muffinNumber"] = muffin_number.to_s  # explicitly add muffinNumber to the defining request
    request.env["collectorNumber"] = collector_number.to_s  # THIS IS SILLY. STOP IT.

    @theMuffins[muffin_number].add_tag(collector_number)

        @log.info("Received tag request with details:" + request.env.inspect)
    zapout "RETURNING MUFFIN NUMBER:#{muffin_number}"
    return muffin_number
  end

end


