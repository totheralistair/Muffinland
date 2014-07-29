# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# 2014-07-27 basic tagging put back in. wanting a "request-parser" thing
# ideas: email, DTO test,

require 'rack'
require 'erb'
require 'erubis'
require 'logger'
require 'set'
require_relative './mrequest.rb'



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
    rreq  = Rack::Request.new(env)
    request = MRackRequest.new( rreq )

    case
      when request.get? then handle_get(request)
      when request.post? then handle_post(request)
#      when request.path=="/post" then handle_post(request)
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
  if muffin_name==""
    muffin_name = "0"
    muffin_number = 0
  end

  case
    when @theHistorian.no_history_to_report
      show_EmptyDB
    when @theBaker.isa_registered_muffin( muffin_number)
      show_muffin_numbered( muffin_number )
    else
      show_404_basic( request, muffin_name )
  end

end

def show_EmptyDB
  respond("EmptyDB.erb", binding( ) )
end

def show_404_basic( request, muffin_name )
  reveal = {
      :requested_name => muffin_name,
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|
            req.requested_muffin_number_str # req.params["MuffinContents"]
          }
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
  @log.info("Just received POST:" + request.inspect)

  @theHistorian.add_request( request )

  case   # dangerous: button names are in the Requests as commands!
    when request.is_Go_command?
      handle_add_new_muffin(request)
    when request.is_Change_command?
      handle_change_muffin(request)
    when request.is_Tag_command?
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

  def initialize( number, request)
#    mreq = MRackRequest.new(request) #REMOVE once Mrequest is done
    @myNumber = number
    new_contents_from_request( request )
    @myTags = Set.new
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
  end

  def raw; @myRaw; end

  def new_contents_from_request( request )
    @myRaw = request.incoming_muffin_contents
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
    request.nameAndNumber_from_path
  end

  def nameAndNumber_from_params( request ) # not sure this belongs here
    request.nameAndNumber_from_params
  end

  def add_new_muffin( request ) # expect Rack::Request, modify the Request!, return muffin number
    muffin_number = @theMuffins.size
    request.add_muffin_number(muffin_number)  #  modify the defining request!!
    @theMuffins << Muffin.new( muffin_number, request )
        @log.info("Added post:" + request.inspect)
    return muffin_number
  end

  def change_muffin_per_request( muffin_number, request ) # modify the Request in place; return nil if bad muffin number
    return nil if !isa_registered_muffin( muffin_number)

    request.add_muffin_number(muffin_number)  #  modify the defining request!!
    @theMuffins[muffin_number].new_contents_from_request( request )

        @log.info("Changed muffin:" + request.inspect)
    return muffin_number
  end

  def tag_muffin_per_request( n_ignored, request ) #really want both numbers coming in here.but ok
    muffin_name = request.requested_muffin_number_str
    muffin_number = number_or_nil( muffin_name )
    return nil if !isa_registered_muffin( muffin_number ) #FAIL! hopefully UI will stop this

    collector_name = request.collector_number_str
    collector_number = number_or_nil( collector_name  )
    return if !isa_registered_muffin( collector_number ) #FAIL! hopefully UI will stop this


    request.add_muffin_number(muffin_number)
    request.add_collector_number(collector_number)

    @theMuffins[muffin_number].add_tag(collector_number)

        @log.info("Received tag request with details:" + request.inspect)
    return muffin_number
  end

end


