# Welcome to Muffinland, the lazy CMS (or something)
# Alistair Cockburn and a couple of really nice friends
# ideas: email, DTO test,

require 'rack'
require 'erb'
require 'erubis'
require 'logger'
require 'set'
require_relative '../src/baker'
require_relative '../src/muffin'
require_relative '../src/historian'
require_relative '../src/ml_request'

def page_from_template( templateFullFn, binding )
  pageTemplate = Erubis::Eruby.new(File.open( templateFullFn, 'r').read)
  pageTemplate.result(binding)
end



class MuffinlandViaRack # Hex adapter to Muffinland from web using Rack

  def initialize( viewsFolder ) #ugh on passing viewsFolder in :(
    @viewsFolder = viewsFolder
    @ml = Muffinland.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def call(env) # hooks into the Rack Request chain

    mlResult = @ml.handle(        # all 'handle's return 'mlResult' DTO
        Ml_RackRequest.new(     # Mrequests wrap various request types/sources
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





class Muffinland
# Muffinland knows global policies and environment, not histories and private things.

  def initialize
    @theHistorian = Historian.new # knows the history of requests
    @theBaker = Baker.new         # knows the muffins
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

#===== UI Edge of the Hexagon =====
# can invoke 'handle(request)' directly.
# input: any class that supports the Ml_request interface
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

end

