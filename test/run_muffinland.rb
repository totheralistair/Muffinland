require_relative '../src/muffinland.rb'

Rack::Handler::WEBrick.run(
    MuffinlandViaRack.new("../src/views/"),
    :Port => 9292
)

