#!/usr/bin/ruby

#require "CommandManager"

class Fortune 
  def initialize()
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
              
  def getFortune(bot, str)
     nick = str[/^:([^!]+)!/, 1]
     target = str[/PRIVMSG (\S+)/, 1]
     if(target == bot.nick || target == "None")
       return
     end
                          
     Kernel.system("wget", "-O", "temp.html", "-T", "150", "http://www.fortunecookiemessage.com/")
     pagetext = get_file_as_string("temp.html")
     #<h1 align="center">
     #              <a href="cookie/7869-Enjoy-life!-It-is-better-to-be-happy-than-wise.">Enjoy life! It is better to be happy than wise.</a></h1>
     #
     if(/<a href="cookie[^>]+>([^<]+)<\/a><\/h1>/.match(pagetext))
       bot.say(target, "Fortune: [#{nick}]: #{$1}#{@suffix}")
       if(@suffix.length == 0)
         @suffix = " "
       else
         @suffix = ""
       end
     end
   end
   
end

m = Fortune.new
CommandManager.add("/fortune", m.method(:getFortune))
CommandManager.add("!fortune", m.method(:getFortune))

