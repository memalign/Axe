#!/usr/bin/ruby

#require "CommandManager"

class Temp
  def initialize()
    @last = Time.now.to_i-30
    @suffix = ""
  end

  def get_file_as_string(filename)
    data = ''
    f = File.open(filename, "r") 
    f.each_line do |line|
      data += line
    end
    f.close
    return data
  end
              
  def getTemp(bot, str)
     now = Time.now.to_i
     if(now-@last < 30)
       puts "ignoring flood!"
       return
     end
     @last = now
     
     nick = str[/^:([^!]+)!/, 1]
     target = str[/PRIVMSG (\S+)/, 1]
     if(target == bot.nick || target == "None")
       return
     end
                          
     Kernel.system("wget", "-O", "temp.html", "-T", "150", "http://www.google.com/pda?q=weather+14850")
     pagetext = get_file_as_string("temp.html")
     if(/<div id="universal"> <div class="a">([^<]+)<br\/><span class=".">(\-?\d+)\&deg\;F<\/span> <span>([^<]+)<\/span>/.match(pagetext))
       temp = $2
       bot.say(target, "Temp: #{$1} #{temp}F #{$3}#{@suffix}")
       if(temp.to_i < 20)
         bot.say(target, "WHOAH, it's COALD!")
       end
       if(@suffix.length == 0)
         @suffix = " "
       else
         @suffix = ""
       end
     end
   end
   
end

m = Temp.new
CommandManager.add("/temp", m.method(:getTemp))
CommandManager.add("!temp", m.method(:getTemp))
CommandManager.add("/weather", m.method(:getTemp))
CommandManager.add("!weather", m.method(:getTemp))

