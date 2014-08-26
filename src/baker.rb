require 'logger'
require 'set'
require 'base64'


class MuffinTin
# known only by the Baker, the MuffinTin
# knows what muffin ids are made from. shhhh top secret.
# The Baker adds, finds, modifies muffins via the MuffinTin

  def initialize
    @muffins = Array.new
  end

  def at( id ) ; @muffins[id]  ;  end
  def next_id ;  @muffins.size ;  end

  def is_legit?( id )
    (id.is_a? Integer) && ( id > -1 ) && ( id < @muffins.size )
  end

  def add_raw( content, content_type="text/plain" )  # muffinTin not allowed to know what contents are.
    m = Muffin.new( next_id, content, content_type )
    @muffins << m
    return m
  end

  def dangerously_all_muffins   #yep, dangerous. remove eventually
    @muffins
  end

  def all_collection_muffin_ids #not dangerous
    s = @muffins.select{ |m| m.collection?}
    i = s.collect{ |m| m.id }
    i
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

  def all_collection_muffin_ids #not dangerous
    @muffinTin.all_collection_muffin_ids
  end

  def muffin_at_GET_request( request )
    id = request.id_from_path   # not sure why Baker knows request from path. suspect
    muffin_at(id) if is_legit?(id)
  end


  def add_muffin_from_text( request ) # modify the Request!
    m = @muffinTin.add_raw( request.incoming_contents )
    request.record_muffin_id( m.id )
    return m
  end

  def make_collection( request )
    return nil unless is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.make_collection
    m
  end

  def make_noncollection( request )
    return nil unless is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.make_noncollection
    m
  end



  def add_muffin_from_file( request ) # modify the Request!
    return nil if !( c = request.content_of_file_upload )
    m = @muffinTin.add_raw( c, request.content_type_of_file_upload )
    request.record_muffin_id( m.id )
    m
  end


  def change_muffin_per_request( request )
    return nil if !is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.new_contents( request.incoming_contents )
    m
  end

  def change_muffin_per_request_by_file( request )
    return nil if ! request.has_legit_file?
    return nil if !is_legit?( id = request.incoming_muffin_id )
    m = muffin_at( id )
    m.new_contents( request.content_of_file_upload, request.content_type_of_file_upload )
    m
end


  def tag_muffin_per_request( request )
    return nil if !is_legit?( id = request.incoming_muffin_id )
    c_id = request.incoming_collector_id
    return nil if !is_legit?( c_id )
    m = muffin_at( id )
    c = muffin_at( c_id )
    m.add_to_collection( c ) ;
    m
  end

end


