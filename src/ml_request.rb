require 'rack'
require 'yaml'


def yaml_my requests
  out = Array.new
  requests.each {|req| out << req.to_yaml }
  out
end

def requests_from_yaml_stream(stream)
  requests = YAML::load_documents( stream ) { |req|
    req.clean_from_yaml
  }
end






#===== class Ml_request =========================
# Ml_request defines the protocol for requests that
# can be sent in to Muffinland.
# Rack::Request to start with, but simpler ones for testing, possibly
# a Rack::Request wrapper
# Warning about Rack::Request, it has two semi-undocumented strange things
# 1. three fields are StringIO, which do not serialize.
#    I have to turn them into strings temporarily to serialize,
#    and recreate them on loading from serializing
# 2. "params" modifies the request, adding the @params inst var
#    i.e. reading the params changes the request
#    This may only matter for testing or serialization.
#    but it is an undocumented side effect of reading params, so watch out.

class Ml_RackRequest
  #note: this pile of accessors looks too complicated to me. Waiting for a simplification

  def initialize( env )
    @myRequest = Rack::Request.new(  env  )
    @myRequest.params # calling params has "side effect" of changing the Request! :(.
    # better to do it now and save later surprises :-(
    @myRequest.env["Muffinland"] = { "Times" => {} }
  end

  def env
    @myRequest.env
  end



  def self.from_yaml yamld_request
    real_request = YAML::load StringIO.new( yamld_request )
    real_request.env["rack.input"] = StringIO.new(  real_request.env["rack.input"]  )
    real_request.env["rack.errors"] = StringIO.new(  real_request.env["rack.errors"]  )

    if real_request.env["rack.request.form_input"]
      real_request.env["rack.request.form_input"] = StringIO.new(  real_request.env["rack.request.form_input"]  )
    end
    real_request
  end

  def to_yaml
    rack_input = @myRequest.env["rack.input"]
    rack_errors = @myRequest.env["rack.errors"]
    form_input = @myRequest.env["rack.request.form_input"]

    @myRequest.env["rack.input"] = rack_input.string if rack_input.class == StringIO
    @myRequest.env["rack.errors"] = rack_errors.string if rack_errors.class == StringIO
    @myRequest.env["rack.request.form_input"] = form_input.string if form_input.class == StringIO

    out = YAML::dump(self)

    @myRequest.env["rack.input"] = rack_input
    @myRequest.env["rack.errors"] = rack_errors
    @myRequest.env["rack.request.form_input"] = form_input
    out
  end

  def clean_from_yaml # cleans up the Stringio fields inside Rack::Request
    Ml_RackRequest::from_yaml( self.to_yaml)
  end



  def theEnv ;  @myRequest.env ; end
  def theParams ;  @myRequest.params ; end
  def thePath ;  @myRequest.path ; end
  def theMuffinlandTags ;  theEnv["Muffinland"] ; end
  def theTimes ;  theMuffinlandTags["Times"] ; end


  def get?; @myRequest.get? ;  end
  def post?; @myRequest.post? || thePath=="/post"            ; end
  def add?;  theParams.has_key?("Add")    ; end
  def change?;  theParams.has_key?("Change") ; end
  def tag?;  theParams.has_key?("Tag")    ; end
  def addByFile?;  theParams.has_key?("Upload")    ; end
  def changeByFile?;  theParams.has_key?("ChangeByFile")    ; end
  def makeCollection?;  theParams.has_key?("Make Collection")    ; end
  def makeNonCollection?;  theParams.has_key?("Make Non-Collection")    ; end

  def command
    case
      when add?       then :add
      when change?    then :change
      when tag?       then :tag
      when addByFile? then :addByFile
      when changeByFile?    then :changeByFile
      when makeCollection?  then :makeCollection
      when makeNonCollection?  then :makeNonCollection
        else nil
    end
  end

  def make_collection? ;  theParams.has_key?("Collection") ? theParams["Collection"] : false ; end

  def name_from_path ;  thePath[ 1..thePath.size ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def incoming_muffin_name;  theParams["MuffinNumber"]   ;  end
  def incoming_muffin_id; n = incoming_muffin_name ; id_from_name( n ) ;  end
  def incoming_collector_name;  theParams["CollectorNumber"] ;  end
  def incoming_collector_id;  id_from_name( incoming_collector_name ) ;  end
  def incoming_contents;  theParams["MuffinContents"] ;  end

  # def has_legit_file? ;
  #  theParams["file"].has_key?(:tempfile)
  # end

  # Record Muffinland sh!t in the request

  def record_in_request( tag, valueString ) ;  theMuffinlandTags[tag] = valueString ;  end
  def record_time( tag ) ; t=Time.now;  theTimes[tag] = "#{t.to_f}";  end

  def record_muffin_id( id ) ;  record_in_request( "muffin_ID", id.to_s ) ;  end
  def record_arrival_time ;  record_time( "Arrived") ; end
  def record_completion_time ; record_time( "Completed");  end

  def arrival_time ; @times["Arrived"] ;  end
  def completion_time ;  @times["Completed"] ; end
  def execution_time ; t = completion_time.to_f - arrival_time.to_f ;end


  def id_from_name( name ) ;  number_or_nil(name) ;  end
  def number_or_nil( s ) # convert string to a number, nil if not a number
    i= s.to_i
    i.to_s == s ? i : nil
  end

end

