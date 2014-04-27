run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello from lambda!\n")] }

#require './src/muffinland'
#run Muffinland.new


