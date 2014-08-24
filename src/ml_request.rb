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
    @myRequest = rack_request
    @params = @myRequest.params           # just convenience these batch
    @env = @myRequest.env
    @env["Muffinland"] = { "Times" => {} }
    @muffinland_tags = @env["Muffinland"]
    @times = @muffinland_tags["Times"]

    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end


  def is_get?; @myRequest.get? ;  end
  def is_post?; @myRequest.post? || @myRequest.path=="/post"            ; end
  def is_Add_command?    ;  @params.has_key?("Add")    ; end
  def is_Change_command? ;  @params.has_key?("Change") ; end
  def is_Tag_command?    ;  @params.has_key?("Tag")    ; end
  def is_Upload_command?    ;  @params.has_key?("Upload")    ; end
  def is_ChangeByFile_command?    ;  @params.has_key?("ChangeByFile")    ; end

  def name_from_path ;  @myRequest.path[ 1..@myRequest.path.size ] ;  end
  def id_from_path ;  id_from_name( name_from_path )     ;  end
  def incoming_muffin_name;  @params["MuffinNumber"]   ;  end
  def incoming_muffin_id; n = incoming_muffin_name ; id_from_name( n ) ;  end
  def incoming_collector_name;  @params["CollectorNumber"] ;  end
  def incoming_collector_id;  id_from_name( incoming_collector_name ) ;  end
  def incoming_contents;  @params["MuffinContents"] ;  end

  def content_type_of_file_upload;
    @params["file"][:type]
  end

  def content_of_file_upload;
    fn = @params["file"][:tempfile].path
    IO.binread(fn)
  end

  # Record Muffinland sh!t in the request

  def record_in_request( tag, valueString ) ;  @muffinland_tags[tag] = valueString ;  end
  def record_time( tag ) ; t=Time.now;  @times[tag] = "#{t.to_f}";  end

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
