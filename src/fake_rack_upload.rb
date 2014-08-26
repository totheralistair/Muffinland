require 'rack'

class FakeRackUpload
  def call env
    req = Rack::Request.new env

    unless req.post? and req.content_type =~ Rack::Multipart::MULTIPART
      return ['400', {}, ['This is a file upload app.']]
    end

    multipart = Rack::Multipart.parse_multipart env
    file_info = multipart.values.find {|f| f.is_a? Hash and f.key? :tempfile }
    body = file_info[:tempfile].read
    file_info[:tempfile].close
    file_info[:tempfile].unlink

    ['500',
     {'Content-Type' => file_info[:type].to_s,
      'Content-Length' => body.bytesize.to_s},
     [body]]
  end
end
