=begin
require_relative '../src/muffinland_deprecated.rb'

Rack::Handler::WEBrick.run(
    Muffinland.new("../src/views/"),
    :Port => 9292
)

=end
