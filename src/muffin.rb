require 'logger'

#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def initialize( id, raw_contents, content_type="text/plain")
    @myID = id
    @myTags = Set.new
    @isCollection = false
    new_contents( raw_contents, content_type )
  end

  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end
  def content_type ;  @myContent_type ;  end
  def add_tag(t) ;  @myTags << t;  self ; end
  def make_collection( yes ) ;  yes ? @isCollection=true : @isCollection=false ;  end
  def collection? ; @isCollection ; end
  def dangerously_all_tags ;  @myTags ;  end  # yes, dangerous. remove one day?


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
