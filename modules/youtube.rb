#!/usr/bin/ruby

#require "CommandManager"

class Youtube
  def get_file_as_string(filename)
    data = ''
    f = File.open(filename, "r") 
    f.each_line do |line|
      data += line
    end
    f.close
    return data
  end
              
  def process(bot, str)
     nick = str[/^:([^!]+)!/, 1]
     target = str[/PRIVMSG (\S+)/, 1]
     if(target == bot.nick || target == "None")
       return
     end
                          
      str.split(" ").each { |tok|
      if(!tok.nil?)
          tok = tok.sub(/^:/, "")
          if(tok.index(/http\:\/\/www\.youtube\.com\/watch/i) == 0)
            Kernel.system("wget", "-O", "temp.html", "-T", "150", tok)

            pagetext = get_file_as_string("temp.html")
            #<meta name="title" content="Run DMC on Reading Rainbow">
            match1 = /\<meta name="title" content="([^"]+)">/.match(pagetext)
            if(!match1.nil? && !match1[1].nil?)
              bot.say(target, "Youtube: #{nick} posted: Title: #{match1[1]}")
              match2 = /\<meta name="description" content="([^"]+)">/.match(pagetext)
              if(!match2.nil? && !match2[1].nil?)
                bot.say(target, "Desc: #{match2[1]}")
              end
            end
            return
          end
       end
    }

  end
end

m = Youtube.new
CommandManager.add("", m.method(:process))
#CommandManager.add("/roll", m.method(:rollDice))
#CommandManager.add("!roll", m.method(:rollDice))

#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
