#!/usr/bin/ruby
require "IrcConn"

class IrcParser

  def IrcParser.process(bot, str)
    
    arr = str.split(" ")
    #if(arr[1] =~ /^\d+$/)
    #puts "ARR1: #{arr[1]}"
    #puts "BOT: #{bot.to_s}"
    checkProtocol(bot, arr[1], str)
    #end
    
    if(str =~ /^PING :(.+)/)
      bot.sock.write("PONG :#$1")
    end
  end
  
  def IrcParser.checkProtocol(bot, num, str)
    #puts "BOT: #{bot.to_s}"
    case num
      when "001"
        bot.doJoins
      when "PRIVMSG"
        bot.gotmsg(str)
      when "PONG"
        bot.updateExpectpong(false)
      when "433" #nick already in use
        bot.appendToNick
    end
    
    bot.protocolHooks(num, str)
  end
  
end
