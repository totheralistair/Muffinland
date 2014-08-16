require './src/muffinland'
run Muffinland.new("./src/views/")


# p.s. here is the simplest rack program, for a reminder
#run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello 3 lambda!\n")] }
#using Rackup


