# :nodoc: namespace
module SpStore 
# :nodoc: namespace
module Benchmark
  
# redefine methods to print detailed timing information
module DetailTiming
    
  def self.setup(clazz, method_name, detail_file_name)
    #find source code
    location      = clazz.instance_method(method_name).source_location
    file_name     = location[0]
    start_line    = location[1]
    function_code = []
    
    File.open( file_name, 'rb' ) do |file|
      line_num = 0
      end_of_function = false
      space    = ""
      file.each do |line|
        line_num += 1
        next if line_num < start_line || end_of_function
        function_code << line
        if line_num == start_line
          line      =~ /(.*)def/
          space     = $1
        end
        end_of_function = true if line =~ /#{space}end/ && line.length == space.size + 4
      end
    end
    
    new_function_code = []
    function_code.each_with_index do |code, index|
      if index == 0
        new_function_code<<code
        new_function_code<<"    dfile = File.open(\"#{detail_file_name}\", \"a\")"
        next
      end
      if index == (function_code.length - 1)
        new_function_code<<code
        next
      end
      if code =~ /return/
        new_function_code<<"    dfile.puts \"\""
        new_function_code<<"    dfile.close"        
        new_function_code<<code
        next
      end
      if index == (function_code.length - 2) # without return
        new_function_code<<"    start = Time.now"
        new_function_code<<"    temp_var = #{code}"
        new_function_code<<"    dfile.print (Time.now - start).to_s + ' '"
        new_function_code<<"    dfile.puts \"\""
        new_function_code<<"    dfile.close"
        new_function_code<<"    temp_var"
        next
      end
      #insert measure commands
      new_function_code<<"    start = Time.now"
      new_function_code<<code
      new_function_code<<"    dfile.print (Time.now - start).to_s + ' '"
    end
    
    #puts new_function_code
    
    #re-define the function
    clazz.class_eval do
      eval new_function_code.join("\n")
    end
    
  end

end # namespace SpStore::Benchmark::DetailTiming

end # namespace SpStore::Benchmark

end # namespace SpStore