#!/usr/bin/ruby

#require "CommandManager"

class Jack 
  def initialize()
    @suffix = ""
    File.open("modules/quotes.txt", 'r') { |f| 
      @quotes = f.readlines
    }
  end
  
  def getJack(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    puts "GOT: #{str}"
    #:Ashen!~Ashen@albex PRIVMSG #thchub.no-ip.org:4000 :/roll 2d6
    channel = str[/PRIVMSG (\#\S+)/, 1]

    if(@suffix.length == 0)
      @suffix = " "
    else
      @suffix = ""
    end

    bot.say(channel, "Jack: #{@quotes[rand(@quotes.length)].chomp}#{@suffix}")
  end
end

m = Jack.new
#CommandManager.add("", m.method(:process))
CommandManager.add("/jack", m.method(:getJack))
CommandManager.add("!jack", m.method(:getJack))

#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
