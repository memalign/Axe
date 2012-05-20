#!/usr/bin/ruby

#require "CommandManager"

class Dice
  def initialize()
    @suffix = ""
  end
  
  def rollDice(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    puts "GOT: #{str}"
    #:Ashen!~Ashen@albex PRIVMSG #thchub.no-ip.org:4000 :/roll 2d6
    channel = str[/PRIVMSG (\#\S+)/, 1]

    if(@suffix.length == 0)
      @suffix = " "
    else
      @suffix = ""
    end

#    if(nick == "wolvie")
#      bot.say(channel, "Roll: #{nick} got 0 -- you suck!#{@suffix}")
#      return
#    end
    
    #what kind of dice?
    diceStr = str[/[\/!]roll(.+)/, 1]
    if(/ (\d+)d(\d+)/.match(diceStr))
      amtDice = $1.to_i
      numSides = $2.to_i
      
      sum = 0
      if(amtDice > 0 && amtDice < 9999)
        1.upto(amtDice) { |x|
          sum += 1 + rand(numSides)
        }
        
        bot.say(channel, "Roll: #{nick} got #{sum}!#{@suffix}")
      end
    end
    #bot.say(channel, line)
  end
end

m = Dice.new
#CommandManager.add("", m.method(:process))
CommandManager.add("/roll", m.method(:rollDice))
CommandManager.add("!roll", m.method(:rollDice))

#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
