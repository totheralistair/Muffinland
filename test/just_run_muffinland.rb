

require_relative '../src/muffinland.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new,
    :Port => 8080
)
