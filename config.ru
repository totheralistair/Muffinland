#run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello 3 lambda!\n")] }
#using Rackup

require './src/muffinland'
run Muffinland.new("./src/views/")

