# Mrequest is the set of classes that know what it is
# that is coming into Muffinland as a request.
# Could be a Rack::Request or a DTORequest for testing

def number_or_nil(string)
  Integer(string)
rescue ArgumentError
  nil
end



class Mrequest


end

#=============================
# a Rack::Request as ML request
class MRackRequest < Mrequest
  require 'rack'
  require 'rack/test'
  require 'logger'

  def initialize( rack_request )
    @myMe = rack_request
  end

  def get?
    @myMe.get?
  end

  def post?
    @myMe.post?
  end

  def is_Go_command?
    @myMe.params.has_key?("Go")
  end

  def is_Change_command?
    @myMe.params.has_key?("Change")
  end

  def is_Tag_command?
    @myMe.params.has_key?("Tag")
  end

  def nameAndNumber_from_path
    path = @myMe.path
    name = path[1..path.size]
    return name, number_or_nil(name)
  end

  def nameAndNumber_from_params
    name = requested_muffin_number_str
    number = number_or_nil(name)
    return name, number
  end

  def incoming_muffin_contents
    @myMe.params["MuffinContents"]
  end

  def requested_muffin_number_str
    @myMe.params["MuffinNumber"]
  end

  def collector_number_str
    @myMe.params["CollectorNumber"]
  end

  def add_muffin_number( n )
    @myMe.env["muffinNumber"] = n.to_s
  end

  def add_collector_number( n )
    @myMe.env["collectorNumber"] = n.to_s
  end



end