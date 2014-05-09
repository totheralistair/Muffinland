#run lambda { |env| [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello 3 lambda!\n")] }

require './src/muffinland_05_page_from_template'
run Muffinland.new("./src/views/")

