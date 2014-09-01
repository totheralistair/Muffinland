# test the 4 ways of sending binayr/ascii data/files to the server app. Thx Filip Zrůst ‏@frzng
require 'rack'
require 'test/unit'
require 'rspec/expectations'
#require 'URI'
require_relative '../src/z_rack_test_app'

# def request_via_API app, method, path, params={}
#   env = Rack::MockRequest.env_for path, method: method, params: params
#   app.call env
# end
class TestRequests < Test::Unit::TestCase



  #===============================
  def test_00_can_upload_ascii_file_via_rack
    puts "\n...starting test_00_can_upload_ascii_file_via_rack"

    app = Z_rack_test_app.new
    params = {  description: 'A text file',
                text_source: Rack::Multipart::UploadedFile.new(
                    '/Users/alistaircockburn/Desktop/README.txt')
    }
    env = Rack::MockRequest.env_for( '/', { method: 'POST', params: params } )
    result = app.call env

    body = result[2][0]
    body.should == File.read('/Users/alistaircockburn/Desktop/README.txt')
  end

  #===============================
  def test_00a_can_upload_ascii_file_into_hexagon
    puts "\n...starting test_00a_can_upload_ascii_file_into_hexagon"

    app = Z_hexagonal_app.new
    params = {  description: 'A text file',
                text_source: Rack::Multipart::UploadedFile.new(
                    '/Users/alistaircockburn/Desktop/README.txt')
    }
    env = Rack::MockRequest.env_for( '/', { method: 'POST', params: params } )
    req = Rack::Request.new env
    result = app.handle req

    body = result[2][0]
    body.should == File.read('/Users/alistaircockburn/Desktop/README.txt')
  end

  #===============================
  def test_01_can_upload_binary_file_via_rack
    puts "\n...starting test_01_can_upload_binary_file_via_rack"

    app = Z_rack_test_app.new
    params = {  description: 'A binary file',
                text_source: Rack::Multipart::UploadedFile.new(
                    '/Users/alistaircockburn/Desktop/2x2.png', "image/png", binary=true )
              }
    env = Rack::MockRequest.env_for( '/', { method: 'POST', params: params } )
    result = app.call env
    body = result[2][0]
    body.should == IO.binread('/Users/alistaircockburn/Desktop/2x2.png')
  end



=begin
  def alistairs_env_for(uri="", opts={})

    # uri = URI(uri)
    # uri.path = "/#{uri.path}" unless uri.path[0] == ?/
    #
    env = {
        "rack.version" => Rack::VERSION,
        "rack.input" => StringIO.new,
        "rack.errors" => StringIO.new,
        "rack.multithread" => true,
        "rack.multiprocess" => true,
        "rack.run_once" => false,
    }

    env["REQUEST_METHOD"] = opts[:method] ? opts[:method].to_s.upcase : "GET"
    # env["SERVER_NAME"] = uri.host || "example.org"
    # env["SERVER_PORT"] = uri.port ? uri.port.to_s : "80"
    # env["QUERY_STRING"] = uri.query.to_s
    # env["PATH_INFO"] = (!uri.path || uri.path.empty?) ? "/" : uri.path
    # env["rack.url_scheme"] = uri.scheme || "http"
    # env["HTTPS"] = env["rack.url_scheme"] == "https" ? "on" : "off"
    #
    # env["SCRIPT_NAME"] = opts[:script_name] || ""
    #
    # if opts[:fatal]
    #   env["rack.errors"] = FatalWarner.new
    # else
    #   env["rack.errors"] = StringIO.new
    # end

    puts "env-1:" + env.inspect

    if params = opts[:params]
      if env["REQUEST_METHOD"] == "GET"
        params = Utils.parse_nested_query(params) if params.is_a?(String)
        params.update(Utils.parse_nested_query(env["QUERY_STRING"]))
        env["QUERY_STRING"] = Utils.build_nested_query(params)
        puts "env-2a:" + env.inspect
      elsif !opts.has_key?(:input)
        opts["CONTENT_TYPE"] = "application/x-www-form-urlencoded"
        if params.is_a?(Hash)
          if data = Utils::Multipart.build_multipart(params)
            opts[:input] = data
            opts["CONTENT_LENGTH"] ||= data.length.to_s
            opts["CONTENT_TYPE"] = "multipart/form-data; boundary=#{Utils::Multipart::MULTIPART_BOUNDARY}"
            puts "env-2b:" + env.inspect
          else
            opts[:input] = Utils.build_nested_query(params)
            puts "env-2c:" + env.inspect
          end
        else
          opts[:input] = params
          puts "env-2d:" + env.inspect
        end
      end
    end
    puts "env-3:" + env.inspect
    empty_str = ""
    empty_str.force_encoding("ASCII-8BIT") if empty_str.respond_to? :force_encoding
    opts[:input] ||= empty_str
    if String === opts[:input]
      rack_input = StringIO.new(opts[:input])
    else
      rack_input = opts[:input]
    end
    puts "env-4:" + env.inspect

    rack_input.set_encoding(Encoding::BINARY) if rack_input.respond_to?(:set_encoding)
    env['rack.input'] = rack_input

    env["CONTENT_LENGTH"] ||= env["rack.input"].length.to_s

    opts.each { |field, value|
      env[field] = value  if String === field
    }
    puts "env-4:" + env.inspect

    env
  end
=end




  #===============================
  def dont_test_02_can_upload_binary_value_via_rack
    puts "\n...starting test_02_can_upload_binary_value_via_rack"
    #this is still a nul test, doesn't actually test anything about uploads

    input = <<EOF
--AaB03x\r
content-disposition: form-data; name="reply"\r
\r
yes\r
--AaB03x\r
content-disposition: form-data; name="fileupload"; filename="dj.jpg"\r
Content-Type: image/jpeg\r
Content-Transfer-Encoding: base64\r
\r
/9j/4AAQSkZJRgABAQAAAQABAAD//gA+Q1JFQVRPUjogZ2QtanBlZyB2MS4wICh1c2luZyBJSkcg\r
--AaB03x--\r
EOF

    app = Z_rack_test_app.new
    params = {
        "Upload" => "Upload",
        "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
        "CONTENT_LENGTH" => input.size,
        :input => input
    }
    # env = alistairs_env_for( '/', { params: params } )
    # puts
    # puts "env 0 = " + env.inspect
    # puts

    env = alistairs_env_for( '/',
                                     "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                     "CONTENT_LENGTH" => input.size,
                                     :input => input
    )
    puts
    puts "env 1 = " + env.inspect
    puts


    env = Rack::MockRequest.env_for("/",
                                  "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                                  "CONTENT_LENGTH" => input.size,
                                  :input => input
    )

    req = Rack::Request.new env
    puts
    puts "env 2 = " + env.inspect
    puts


  puts "first req: " + req.inspect
  puts "first req.POST: " + req.POST.inspect
#    req.POST.should =~ "fileupload"
#    req.POST.should.include "reply"
  req.content_length== input.size
  req.media_type== 'multipart/form-data'
  req.media_type_params['boundary']== 'AaB03x'
  req.POST["reply"]== "yes"
  f = req.POST["fileupload"]
  f[:type]== "image/jpeg"
  f[:filename]== "dj.jpg"
  f[:tempfile].size.should== 76
# req.should.be.form_data
 req.content_length.should== input.size
 req.media_type.should== 'multipart/form-data'
# req.media_type_params.should.include 'boundary'
 req.media_type_params['boundary'].should== 'AaB03x'
 req.POST["reply"].should== "yes"
# f.should.be.kind_of Hash
# f.should.include :tempfile

  # result = request_via_API( app,
  #                             "POST",
  #                             '/ignored',
  #                              "Upload"=>"Upload",
  #                              "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
  #                              "CONTENT_LENGTH" => input.size,
  #                              :input => input)

    result = app.call env
    puts
    puts "Received result:#{result.inspect}"


    exp = {
      out_action: "GET_named_page",
    }
    exp.should == exp

    puts "test_05_can_upload_file done"
  end

end
