require 'logger'

#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def self.new_muffin_from( id, raw_contents, content_type="text/plain" )
    case content_type
      when "text/plain"
        return TextMuffin.new( id, raw_contents, content_type )
      else
        return BinaryMuffin.new( id, raw_contents, content_type )
    end
  end

  def initialize( id, raw_contents, content_type="text/plain")
    @myID = id
    @belongs_to_collections = Set.new
    @isCollection = false
    @collects_muffins = Set.new
    new_contents( raw_contents, content_type )
  end



  def add_tag(t) ;  @belongs_to_collections << t;  self ; end
  def belongs_to_ids ; s = @belongs_to_collections.collect{ |m| m.id}; s; end
  def collection? ; @isCollection ; end
  def collects_ids ; s = @collects_muffins.collect{ |m| m.id} ;  s ;  end
  def collect_muffin ( m ) ; @collects_muffins << m ; end
  def content_type ;  @myContent_type ;  end
  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end

  # Note! Making a collection does not not change the collection contents!! is correct (I think)
  # so you can make a collection a non-collection and it still has the collected references.
  # reverse it, and the collected set "reappears". I /think/ this is a good idea.?
  def make_collection ;  @isCollection=true; end
  def make_noncollection ;  @isCollection=false;  end

  def add_to_collection ( c )
    return nil if !c.collection?
    @belongs_to_collections << c
    c.collect_muffin( self )
  end

  def new_contents( raw_contents, content_type="text/plain" ) # BAD, need to get rid of defaultness arg 2.
    @myContent_type = content_type
    @myRaw = raw_contents
    self
  end

end

class BinaryMuffin < Muffin
  def for_viewing
        '<img src="data:image/png;base64,' + Base64.encode64(raw) + '" /> '
  end
end

class TextMuffin < Muffin
  def for_viewing
        raw
  end
end