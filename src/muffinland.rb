# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require 'logger'
require_relative '../src/mlResponses' # the API output defined for Muffinland
require_relative '../src/baker'
require_relative '../src/muffin'
require_relative '../src/historian'
require_relative '../src/ml_request'


class Muffinland
# Muffinland knows global policies and environment, not histories and private things.

  def initialize
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
    @log = Logger.new(STDOUT); @log.level = Logger::INFO
  end

#===== Visitor Edge of the Hexagon =====
# invoke 'handle(request)' directly.
# input: any class that supports the Ml_request interface
# output: a hash with all the data produced for consumption

  def handle( request ) # note: all 'handle's return 'mlResponse' in a chain
    request.record_arrival_time
    mlResponse =
        case
          when request.get? then handle_get_muffin(request)
          when request.post? then handle_post(request)
        end
    request.record_completion_time
    mlResponse
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
                   when request.add?        then  handle_add_muffin(request)
                   when request.adddByFile? then  handle_add_by_file(request)
                   when request.change?     then  handle_change_muffin(request)
                   when request.changeByFile? then  handle_change_by_file(request)
                   when request.tag?        then  handle_tag_muffin(request)
                 else                            handle_unknown_post(request)
               end
  end

  def handle_unknown_post( request )
    @log.info "DOIN NUTHNG. not a recognized command"
    mlResponse_for_UnregisteredCommand
  end

  def handle_add_muffin( request )
    m = @theBaker.add_muffin_from_text(request)
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request )
  end

  def handle_add_by_file( request )   # scratchy functions, largely breaking other things
    m = @theBaker.add_muffin_from_file(request)
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request )
  end

  def handle_change_muffin( request )
    m = @theBaker.change_muffin_per_request( request )
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request )
  end

  def handle_change_by_file( request )
    m = @theBaker.change_muffin_per_request_by_file( request )
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request )
  end

  def handle_tag_muffin( request )
    m = @theBaker.tag_muffin_per_request( request )
    m ? mlResponse_for_GET_muffin( m ) :
        mlResponse_for_404_basic( request ) # not correct, cuz failure may be collector id
  end


end

