#!/usr/bin/ruby
require "IrcConn"

class IrcClientParser
  def IrcClientParser.process(client, irc, str)
    if(str =~ /^PING :(.+)/)
      client.raise(0, irc, ["PONG :#$1"]) # 0 means send to socket
    else
      arr = str.split(" ")
      IrcClientParser.checkProtocol(client, irc, arr[1], str)
    end
  end
  
  def IrcClientParser.checkProtocol(client, irc, num, str)
    #:Axe!~axe@user-12l2fv9.cable.mindspring.com JOIN :#a
    args = str.split(" ")
    case num
      when "001"
        #bot.doJoins
      when "332"
        #:meatmanek.ath.cx 332 Axe #a :asdf
        arr = str.split(" ", 5)
        topic = arr[4][1,arr[4].length-1]
        client.raise(4, irc, [arr[3], topic, arr[2]])
        client.raise(2, irc, [arr[3], "-!- The topic for #{arr[3]} was set to \""+topic.chomp+"\" by #{arr[2]}"])
      when "PRIVMSG"
        msg = str.split(" ", 4)[3]
        msg = msg[1, msg.length-1]
        nick = (args[0].split("!")[0])
        nick = nick[1, nick.length-1]
        msg = "<"+nick+"> " + msg
        client.raise(2, irc, [args[2], msg]) # 2 means send to the "channel" at [0]
      when "JOIN"
        t = (args[0].split("!")[0])
        #client.put(0, 20, "A0: "+t[1,t.length-1].to_s+" n: "+irc.nick.to_s)
        if(t[1,t.length-1].to_s.casecmp(irc.nick.to_s) == 0)
          #client.put(0, 21, "asdf")
          dims = [1, 16, 26, 25]#window.getDimensions
          client.addWin(irc, CursesChannelWindow.new((args[2])[1,args[2].length-1],dims[0],dims[1],dims[2],dims[3], client))
          #client.put(0, 21, "asdf")
        else
          msg = "-!- "+t[1,t.length-1]+" has joined "+args[2][1,args[2].length-1]
          client.raise(2, irc, [args[2][1,args[2].length-1], msg])
        end
      when "NICK"
        t = (args[0].split("!")[0])
        t = t[1,t.length-1]
        nick = (args[0].split("!")[0])
        nick = nick[1,nick.length-1]
        if(t.to_s.casecmp(irc.nick.to_s) == 0)
          irc.nick = args[2][1,args[2].length-1]
          client.raise(3, irc, ["-!- You are now known as "+irc.nick]) 
        else
          #find all windows with this person
          client.raise(2, irc, [0,"-!- "+str])
        end
      when "TOPIC"
        t = (args[0].split("!")[0])
        t = t[1,t.length-1]
        arr = str.split(" ", 4)
        client.raise(4, irc, [args[2], arr[3][1,arr[3].length-1], t])
        client.raise(2, irc, [args[2], "-!- The topic for #{args[2]} has been set to \""+arr[3][1,arr[3].length-1].chomp+"\" by #{t}"])
      else
        if(str)
          client.raise(2, irc, [0,"-!- "+str])
        end
    end
  end
  
end
