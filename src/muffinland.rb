# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require 'logger'
require_relative '../src/baker'
require_relative '../src/muffin'
require_relative '../src/historian'
require_relative '../src/ml_request'


class Muffinland
# Muffinland knows global policies and environment, not histories and private things.

  def initialize
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

#===== Visitor Edge of the Hexagon =====
# can invoke 'handle(request)' directly.
# input: any class that supports the Ml_request interface
# output: a hash with all the data produced for consumption

  def handle( request ) # note: all 'handle's return 'mlResponse' in a chain
    request.record_arrival_time
    @log.info("Just arrived:" + request.inspect)

    mlResponse =
        case
          when request.is_get? then handle_get_muffin(request)
          when request.is_post? then handle_post(request)
        end

    request.record_completion_time

    @log.info("Just completed:" + request.inspect)
    mlResponse
  end

#===== the set of outputs produced: =====

  def mlResponse_for_EmptyDB
    mlResponse = { :out_action => "EmptyDB" }
  end

  def mlResponse_for_UnregisteredCommand
    mlResponse = { :out_action => "Unregistered Command" }
  end

  def mlResponse_for_404_basic( request )
    mlResponse = {
        :out_action => "404",
        :requested_name => request.name_from_path,
        :dangerously_all_muffins_raw =>
            @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
        :dangerously_all_posts =>
            @theHistorian.dangerously_all_posts.map{|req|req.inspect}
    }
  end

  def mlResponse_for_GET_muffin( muffin )
    mlResponse = {
        :out_action => "GET_named_page",
        :muffin_id => muffin.id,
        :muffin_body => muffin.raw,
        :tags => muffin.dangerously_all_tags,
        :dangerously_all_muffins_raw =>
            @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
        :dangerously_all_posts =>
            @theHistorian.dangerously_all_posts.map{|req|req.inspect}
    }
  end




#===== The commands to be handled (and the handling)=======

  def handle_get_muffin( request )
    m = @theBaker.muffin_at_GET_request( request )
    mlResponse =
        case
          when @theHistorian.no_history_to_report?
            mlResponse_for_EmptyDB
          when m
            mlResponse_for_GET_muffin( m )
          else
            mlResponse_for_404_basic( request )
        end
  end


  def handle_post( request )
    @theHistorian.add_request( request )
    mlResponse = case
                 when request.is_Add_command?    then  handle_add_muffin(request)
                 when request.is_Change_command? then  handle_change_muffin(request)
                 when request.is_Tag_command?    then  handle_tag_muffin(request)
                 when request.is_Upload_command? then  handle_upload_file(request)
                 else                          handle_unknown_post(request)
               end
  end

  def handle_unknown_post( request )
    @log.info "DOIN NUTHNG. not a recognized command"
    mlResponse_for_UnregisteredCommand
  end

  def handle_add_muffin( request )
    m = @theBaker.add_muffin(request)
    mlResponse_for_GET_muffin( m )
  end

  def handle_change_muffin( request )
    m = @theBaker.change_muffin_per_request( request )
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request )
  end

  def handle_tag_muffin( request )
    m = @theBaker.tag_muffin_per_request( request )
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request ) # not correct, cuz failure may be collector id
  end

  def handle_upload_file( request )   # just barely stasted, not working yet
    @log.info "File upload requested, let's see"
    mlResponse_for_404_basic( request )
  end

=begin

@params={
  "file"=>{
    :filename=>"4x4.png",
    :type=>"image/png",
    :name=>"file",
    :tempfile=>#<
      Tempfile:/var/folders/2d/9q3nv99167l4w3qwqv8jj8140000gn/T/RackMultipart20140816-35691-1p3puwp
      >,
    :head=>"Content-Disposition: form-data; name=\"file\"; filename=\"4x4.png\"\r\nContent-Type: image/png\r\n"},
    "submit"=>"Submit"
  }>,
@log=#<Logger:0x0000010186f5e0
@progname=nil,
@level=1,
@default_formatter=#<Logger::Formatter:0x0000010186f4c8
@datetime_format=nil>,
@formatter=nil,
@logdev=#<Logger::LogDevice:0x0000010186f428
@shift_size=nil,
@shift_age=nil,
@filename=nil,
@dev=#<IO:<STDOUT>>,
@mutex=#<Logger::LogDevice::LogDeviceMutex:0x0000010186f400
@mon_owner=nil,
@mon_count=0,
@mon_mutex=#<Mutex:0x0000010186f338>>>>>

=end

end

