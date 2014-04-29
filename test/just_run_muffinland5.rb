

require_relative '../src/Muffinland5.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new("../src/views/"),
    :Port => 8080
)

