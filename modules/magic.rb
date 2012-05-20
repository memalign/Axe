#!/usr/bin/ruby

#require "CommandManager"

class Magic 
  def initialize()
    @suffix = ""
    File.open("modules/magic.txt", 'r') { |f| 
      @quotes = f.readlines
    }
  end
  
  def getMagic(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    puts "GOT: #{str}"
    #:Ashen!~Ashen@albex PRIVMSG #thchub.no-ip.org:4000 :/roll 2d6
    channel = str[/PRIVMSG (\#\S+)/, 1]

    if(@suffix.length == 0)
      @suffix = " "
    else
      @suffix = ""
    end

    if(/[\/!]magic.*(homework|study).*/i.match(str))
      bot.say(channel, "Magic: not like it'll raise your grade anyway...#{@suffix}")
    else
      bot.say(channel, "Magic: #{@quotes[rand(@quotes.length)].chomp}#{@suffix}")
    end
  end
end

m = Magic.new
#CommandManager.add("", m.method(:process))
CommandManager.add("/magic", m.method(:getMagic))
CommandManager.add("!magic", m.method(:getMagic))

#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
