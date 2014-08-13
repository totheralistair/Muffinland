=begin
# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require 'rack'
require 'erb'
require 'erubis'
require 'logger'
require 'set'



#===== These i/o utilities should be in a shared place one day =====
def page_from_template( templateFullFn, binding )
    pageTemplate = Erubis::Eruby.new(File.open( templateFullFn, 'r').read)
    pageTemplate.result(binding)
end

def zapout( str )
  print "\n #{str} \n"
end

#=========================================
# Muffinland know global policies and environment, not histories and private things.
class Muffinland

  def initialize(viewsFolder)
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
    @viewsFolder = viewsFolder    # I could hope this goes away one day, ugh.
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def call(env) #this hooks into the Rack Request chain for Rack-driven use
    mlResult = handle(        # all 'handle's return 'mlResult' DTO
        MRackRequest.new(     # Mrequests wrap various request types/sources
            Rack::Request.new(env) ) )

    @log.info("mlResult:" + mlResult.inspect)

    page = page_from_template(
        @viewsFolder + mlResult[:html_template_fn],
        binding )

    response = Rack::Response.new
    response.write( page )
    response.finish
  end
end

#===== UI Edge of the Hexagon =====
# you can invoke 'handle(request)' directly
# input: any class that supports the Mrequest interface
# output: a hash with all the data produced for consumption

def handle( request ) # note: all 'handle's return 'mlResult' in a chain
  request.record_time( "ml_arrival_time", Time.now )
  @log.info("Just arrived:" + request.inspect)
  mlResult =
      case
        when request.get? then handle_get_muffin(request)
        when request.post? then handle_post(request)
      end
  request.record_time( "ml_completion_time", Time.now )
  @log.info("Just completed:" + request.inspect)
  mlResult
end

#===== the set of outputs produced: =====

def mlResult_for_EmptyDB
  mlResult = { :html_template_fn => "EmptyDB.erb" }
end

def mlResult_for_404_basic( request )
  mlResult = {
      :html_template_fn => "404.erb",
      :requested_name => request.name_from_path,
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|
            req.incoming_muffin_name }
  }
end

def mlResult_for_GET_muffin( muffin )
  mlResult = {
      :html_template_fn => "GET_named_page.erb",
      :muffin_id => muffin.id,
      :muffin_body => muffin.raw,
      :tags => muffin.dangerously_all_tags,
      :dangerously_all_muffins =>
          @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
      :dangerously_all_posts =>
          @theHistorian.dangerously_all_posts.map{|req|req.inspect}
  }
end




#===== The commands to be handled (and the handling)=======

def handle_get_muffin( request )
  m = @theBaker.muffin_at_GET_request( request )
  mlResult =
      case
        when @theHistorian.no_history_to_report?
          mlResult_for_EmptyDB
        when m
          mlResult_for_GET_muffin( m )
        else
          mlResult_for_404_basic( request )
      end
end


def handle_post( request )
  @theHistorian.add_request( request )
  mlResult = case
    when request.is_Add_command?    then  handle_add_muffin(request)
    when request.is_Change_command? then  handle_change_muffin(request)
    when request.is_Tag_command?    then  handle_tag_muffin(request)
      else                          handle_unknown_post(request)
  end
end

def handle_unknown_post( request )
  @log.info "DOIN NUTHNG. not a recognized command"
  # not correct, should respond mlResult and do ?something?
end

def handle_add_muffin( request )
  m = @theBaker.add_muffin(request)
  mlResult_for_GET_muffin( m )
end

def handle_change_muffin( request )
  m = @theBaker.change_muffin_per_request( request )
  m ? mlResult_for_GET_muffin( m ) :
      mlResult_for_404_basic( request )
end

def handle_tag_muffin( request )
  m = @theBaker.tag_muffin_per_request( request )
  m ? mlResult_for_GET_muffin( m ) :
      mlResult_for_404_basic( request ) # not correct, cuz failure may be collector id
end


#===== class Historian ==============
# knows the history of what has happened, all Posts

class Historian

  def initialize
    @thePosts = Array.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def no_history_to_report?;  @thePosts.size == 0 ;  end
  def dangerously_all_posts ;  @thePosts ;  end  #yep, dangerous. remove eventually


  def add_request( request )
    @thePosts << request
  end

end


#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def initialize( id, raw_contents)
    @myID = id
    @myRaw = raw_contents
    @myTags = Set.new
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
  end

  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end
  def new_contents( c );  @myRaw = c ;  self ;  end
  def add_tag(t) ;  @myTags << t;  self ; end
  def dangerously_all_tags ;  @myTags ;  end  # yes, dangerous. remove one day?

end

#===== class MuffinTin ==============
# known only by the Baker, the MuffinTin
# knows what muffin ids are made from. shhhh top secret.
# The Baker adds, finds, modifies muffins via the MuffinTin

class MuffinTin

  def initialize
    @muffins = Array.new
  end

  def at( id ) ; @muffins[id]  ;  end
  def next_id ;  @muffins.size ;  end

  def is_legit?( id )
    (id.is_a? Integer) && ( id > -1 ) && ( id < @muffins.size )
  end

  def add_raw( content )  # muffinTin not allowed to know what contents are.
    m = Muffin.new( next_id, content )
    @muffins << m
    return m
  end

  def dangerously_all_muffins   #yep, dangerous. remove eventually
    @muffins
  end

end

#===== class Baker ==============
# knows the handlings of muffins.

class Baker

  def initialize
    @muffinTin = MuffinTin.new
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
  end

  def muffin_at(id) ;  @muffinTin.at( id ) ;  end
  def is_legit?(id) ;  @muffinTin.is_legit?(id) ;  end

  def dangerously_all_muffins   #yep, dangerous. remove eventually
    @muffinTin.dangerously_all_muffins
  end

  def muffin_at_GET_request( request )
    id = request.id_from_path   # not sure why Baker knows request from path. suspect
    muffin_at(id) if is_legit?(id)
  end


  def add_muffin( request ) # modify the Request!
    m = @muffinTin.add_raw( request.incoming_contents )
    request.record_muffin_id( m.id )  #  Look Out! modify the defining request!!
    #the reason for this is this is the only record of the id of the new muffin
    return m
  end


  def change_muffin_per_request( request )
    return nil if !is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.new_contents( request.incoming_contents )
    m
  end


  def tag_muffin_per_request( request )
    return nil if !is_legit?( id = request.incoming_muffin_id )
    collector_id = request.incoming_collector_id
    return nil if !is_legit?( collector_id )
    m = muffin_at( id )
    m.add_tag( collector_id )
    m
  end

end




#===== class Mrequest =========================
# Mrequest defines the protocol for requests that
# can be sent in to Muffinland.
# Rack::Request to start with, but simpler ones for testing, possibly

class Mrequest

  #nothing implemented at this level yet.

end


#==================================
# a Rack::Request wrapper

class MRackRequest < Mrequest
  #note: this pile of accessors looks too complicated to me. Waiting for a simplification

  def initialize( rack_request )
    @myMe = rack_request
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO

  end

  def get?  ; @myMe.get? ;  end
  def post? ; @myMe.post? || @myMe.path=="/post"            ; end
  def is_Add_command?    ;  @myMe.params.has_key?("Add")    ; end
  def is_Change_command? ;  @myMe.params.has_key?("Change") ; end
  def is_Tag_command?    ;  @myMe.params.has_key?("Tag")    ; end

  def name_from_path ;  @myMe.path[ 1..@myMe.path.size ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def incoming_muffin_name;  @myMe.params["MuffinNumber"]   ;  end
  def incoming_muffin_id;  id_from_name( incoming_muffin_name ) ;  end
  def incoming_collector_name;  @myMe.params["CollectorNumber"] ;  end
  def incoming_collector_id;  id_from_name( incoming_collector_name ) ;  end
  def incoming_contents;  @myMe.params["MuffinContents"] ;  end

  # When needed: Modify the request itself
  def record_muffin_id( n ) ;  @myMe.env["ml_muffin_ID"] = n.to_s ;  end
  def record_time( tag, t ) ; @myMe.env[tag] = "#{t} ms:#{t.usec}" ;  end

  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil(string) # convert string to a number, nil if not a number
    Integer(string)         # here do any possible conversion
    rescue ArgumentError    # here mark impossible conversions
      nil                   # personally I find this little method distressing
  end                       # but what do I know.

end=end
