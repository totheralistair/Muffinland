require 'rack'
require 'logger'

#===== class Ml_request =========================
# Ml_request defines the protocol for requests that
# can be sent in to Muffinland.
# Rack::Request to start with, but simpler ones for testing, possibly

class Ml_request

  #nothing implemented at this level yet.

end


#==================================
# a Rack::Request wrapper

class Ml_RackRequest < Ml_request
  #note: this pile of accessors looks too complicated to me. Waiting for a simplification

  def initialize( rack_request )
    @myMe = rack_request
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO

  end

  def is_get?; @myMe.get? ;  end
  def is_post?; @myMe.post? || @myMe.path=="/post"            ; end
  def is_Add_command?    ;  @myMe.params.has_key?("Add")    ; end
  def is_Change_command? ;  @myMe.params.has_key?("Change") ; end
  def is_Tag_command?    ;  @myMe.params.has_key?("Tag")    ; end
  def is_Upload_command?    ;  @myMe.params.has_key?("Upload")    ; end

  def name_from_path ;  @myMe.path[ 1..@myMe.path.size ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def incoming_muffin_name;  @myMe.params["MuffinNumber"]   ;  end
  def incoming_muffin_id;  id_from_name( incoming_muffin_name ) ;  end
  def incoming_collector_name;  @myMe.params["CollectorNumber"] ;  end
  def incoming_collector_id;  id_from_name( incoming_collector_name ) ;  end
  def incoming_contents;  @myMe.params["MuffinContents"] ;  end

  # When needed: Modify the request itself

  def record( tag, valueString ) ;  @myMe.env[tag] = valueString ;  end
  def record_muffin_id( id ) ;  record( "ml_muffin_ID", id.to_s ) ;  end
  def record_arrival_time ; t=Time.now; record( "ml_arrival_time", "#{t} ms:#{t.usec}" ) ;  end
  def record_completion_time ; t=Time.now; record( "ml_completion_time", "#{t} ms:#{t.usec}" ) ;  end


  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil(string) # convert string to a number, nil if not a number
    Integer(string)         # here do any possible conversion
  rescue ArgumentError    # here mark impossible conversions
    nil                   # personally I find this little method distressing
  end                       # but what do I know.

end


#==================================
# a Ml_request wrapper for simple testing and API usage

class Ml_request_simple < Ml_request
  def initialize
    @myMe = Hash.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def self.build( method, path, params={} ) # simulate building a rack request
    r = new
    r.method(method)
    r.path(path)
    r.params(params)
  end

  def record( tag, valueString ) ;  @myMe[tag] = valueString ; self ;  end

  def method( s ) ; record("Method", s ) ; end
  def path( s ) ; record("Path", s ) ; end
  def params( h ) ; record("Params", h ) ; end

  def is_get?; @myMe["Method"]=="GET" ;  end
  def is_post?; @myMe["Method"]=="POST" ;  end
  def is_Add_command?    ; @myMe["Params"].has_key?("Add")    ; end
  def is_Change_command?    ;  @myMe["Params"].has_key?("Change")    ; end
  def is_Tag_command?    ;  @myMe["Params"].has_key?("Tag")    ; end
  def is_Upload_command?    ;  @myMe["Params"].has_key?("Upload")    ; end

  def name_from_path ;  n=@myMe["Path"].size; @myMe["Path"][ 1..n ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def incoming_muffin_name;  @myMe["MuffinName"]   ;  end
  def incoming_muffin_id;  id_from_name( incoming_muffin_name ) ;  end
  def incoming_collector_name;  @myMe["CollectorName"] ;  end
  def incoming_collector_id;  id_from_name( incoming_collector_name ) ;  end
  def incoming_contents;  @myMe["Params"]["MuffinContents"] ;  end


  # When needed: Modify the request itself

  def record_muffin_id( id ) ;  record( "ml_muffin_ID", id.to_s ) ;  end
  def record_arrival_time ; t=Time.now; record( "ml_arrival_time", "#{t} ms:#{t.usec}" ) ;  end
  def record_completion_time ; t=Time.now; record( "ml_completion_time", "#{t} ms:#{t.usec}" ) ;  end


  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil(string) # convert string to a number, nil if not a number
    Integer(string)         # here do any possible conversion
  rescue ArgumentError      # here mark impossible conversions
    nil                     # personally I find this little method distressing
  end                       # but what do I know.

end
