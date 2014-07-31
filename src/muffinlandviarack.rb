# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require 'rack'
require 'erb'
require 'erubis'
require 'logger'
require 'set'

#===== Muffinland via Rack (hex adapter) =====

class MuffinlandViaRack

  def initialize( viewsFolder ) #ugh on passing viewsFolder in :(
    @viewsFolder = viewsFolder
    @ml = Muffinland.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def call(env) # hooks into the Rack Request chain

    mlResult = @ml.handle(        # all 'handle's return 'mlResult' DTO
        MRackRequest.new(     # Mrequests wrap various request types/sources
            Rack::Request.new(env) ) )

    @log.info("Result Pack:" + mlResult.inspect)

    page = page_from_template(
        @viewsFolder + mlResult[:html_template_fn],
        binding )

    response = Rack::Response.new
    response.write( page )
    response.finish
  end

end




#===== i/o utilities ()should be in a shared place one day) =====

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

  def initialize
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end


#===== UI/web port of the Hexagon =====
# 'handle(request)' is the ui port (for http/cmd/test driven use)
# input: any class that supports the Mrequest interface
# output: a hash with all the data produced for consumption

  def handle( request ) # note: all 'handle's return 'mlResult' in a chain
    mlResult =
        case
          when request.get? then handle_get_muffin(request)
          when request.post? then handle_post(request)
        end
  end

  #----- the set of outputs produced: -------

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
    @log.info("Just received POST:" + request.inspect)
    @theHistorian.add_request( request )
    case
      when request.is_Add_command?    then  handle_add_muffin(request)
      when request.is_Change_command? then  handle_change_muffin(request)
      when request.is_Tag_command?    then  handle_tag_muffin(request)
        else                          @log.info "DOIN NUTHNG. not a recognized command"
    end
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
  def add_request( request ) ;  @thePosts << request ;  end

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
  def record_muffin_id( n ) ;  @myMe.env["muffinID"] = n.to_s ;  end

  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil(string) # convert string to a number, nil if not a number
    Integer(string)         # here do any possible conversion
    rescue ArgumentError    # here mark impossible conversions
      nil                   # personally I find this little method distressing
  end                       # but what do I know.

end