

require_relative '../src/muffinland_09_cumulative_db.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new("../src/views/"),
    :Port => 8080
)

