require 'logger'

#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def initialize( id, raw_contents, content_type="text/plain")
    @myID = id
    @belongs_to_collections = Set.new
    @isCollection = false
    @collects_muffins = Set.new
    new_contents( raw_contents, content_type )
  end

  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end
  def content_type ;  @myContent_type ;  end
  def add_tag(t) ;  @belongs_to_collections << t;  self ; end
  def make_collection ;  @isCollection=true; end
  def make_noncollection ;  @isCollection=false;  end
  def collection? ; @isCollection ; end

  def add_to_collection ( c )
    @belongs_to_collections << c
    c.collect_muffin( self )
  end
  def collect_muffin ( m )
    @collects_muffins << m
  end

  def all_collected_muffins_ids
    s = @collects_muffins.collect{ |m| m.id}
    s
  end


  def belongs_to_collections_ids
    s = @belongs_to_collections.collect{ |m| m.id}
    s
  end


  def new_contents( raw_contents, content_type="text/plain" )
    @myContent_type = content_type
    @myRaw = raw_contents
    self
  end

  def for_viewing
    b64 = '<img src="data:image/png;base64,' + Base64.encode64(raw) + '" /> '
    content_type == 'text/plain' ? raw : b64
  end

end
