require_relative '../src/muffinland_via_rack.rb'

Rack::Handler::WEBrick.run(
    Muffinland_via_rack.new("../src/views/"),
    :Port => 9292
)

