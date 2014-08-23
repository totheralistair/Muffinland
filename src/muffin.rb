require 'logger'

#===== class Muffin ==============
# knows or can produce everything about itself. Knows nothing else

class Muffin

  def initialize( id, raw_contents, content_type="text/plain")
    @myID = id
    @myRaw = raw_contents
    @myContent_type = content_type
    @myTags = Set.new
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
  end

  def id  ;  @myID  ;  end
  def raw ;  @myRaw ;  end
  def content_type ;  @myContent_type ;  end
  def new_contents( c );  @myRaw = c ;  self ;  end
  def add_tag(t) ;  @myTags << t;  self ; end
  def dangerously_all_tags ;  @myTags ;  end  # yes, dangerous. remove one day?

end
