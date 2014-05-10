

require_relative '../src/muffinland_10_cumulative_db.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new("../src/views/"),
    :Port => 8080
)

