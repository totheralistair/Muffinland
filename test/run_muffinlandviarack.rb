require_relative '../src/muffinlandviarack.rb'

Rack::Handler::WEBrick.run(
    MuffinlandViaRack.new("../src/views/"),
    :Port => 9292
)

