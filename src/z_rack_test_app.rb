require 'rack'

class Z_rack_test_app
# adapter to support Rack real and test drivers
 def call env
    puts
    puts "Z_rack_test_app received env:" + env.inspect
    puts ''

    req = Rack::Request.new env
    out = Z_hexagonal_app.new.handle( req )

    puts "Z_rack_test_app done. out=" + out.inspect
    out
  end
end

class Z_hexagonal_app
# the pure hexagonal app

  def handle( req )
    puts
    puts "Handle request:" + req.inspect
    puts "req.content type=" + req.content_type.inspect
    puts

    case
      when req.get?
        handle_get req
      when ( req.post? and req.content_type == "application/x-www-form-urlencoded" )
        handle_form req
      when ( req.post? and req.content_type =~ Rack::Multipart::MULTIPART )
        multipart_thingy req
      else
        handle_unknown req
    end
  end

  def handle_get req
    ['400', {}, ['This is a file upload app.']]
  end

  def handle_form req
    ['400', {}, ['application/x-www-form-urlencoded: not implemented yet.']]
  end

  def multipart_thingy req
    # works for binary and ascii file uploads
    env = req.env
    multipart = Rack::Multipart.parse_multipart env
    ; puts "In Multipart Thingy:" + multipart.values.inspect

    file_info = multipart.values.find {|f| f.is_a? Hash and f.key? :tempfile }
    ; puts file_info.inspect


    type = file_info[:type]
    ; puts type
    body = file_info[:tempfile].read
    file_info[:tempfile].close
    file_info[:tempfile].unlink
    ['500',
     {'Content-Type' => file_info[:type].to_s,
      'Content-Length' => body.bytesize.to_s},
     [body]]
  end

  def handle_unknown req
    ['400', {}, ['This is a file upload app.']]
  end

end