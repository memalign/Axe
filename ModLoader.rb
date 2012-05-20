#!/usr/bin/ruby
require "CommandManager"

class ModLoader

  def ModLoader.loadModules(dir)
    CommandManager.clear
    Dir.foreach(dir) { |file|
      if(file =~ /\.rb$/)
        puts "[loadModules] Including #{dir + file}"
        load dir + file
      end
    }
  end
  
  def ModLoader.loadCore
    CommandManager.clear
    Dir.foreach("./") { |file|
      #puts "ZERO: #{$0}"
      file = "./" + file
      if(file =~ /\.rb$/)
        if("./"+$0+".rb" !~ /#{file}/)
          puts "[loadCore] Including #{file}"
          load file
        end
      end
    }
  end

end
