#!/usr/bin/ruby
#require "CommandManager"

class Nag 
  def initialize()
    @suffix = ""
    @nags = Hash.new
    File.open("modules/nag.txt", 'r') { |f| 
      f.readlines.each { |l|
          arr = l.chomp.split("\t")
          name = arr[0].upcase
          @nags[name] = arr[1]
      }
    }
  end

  def save 
    File.open("modules/nag.txt", 'w') { |f|
        @nags.keys.each { |s|
            if(!s.nil? && !@nags[s].nil?)
                f.write("#{s}\t#{@nags[s]}\n")
            end
        }
    }
  end

  def makeNag(bot, str)
      nick = str[/^:([^!]+)!/, 1]
      channel = str[/PRIVMSG (\#\S+)/, 1]
      recv = str[/PRIVMSG \#\S+ \:\S+ (\S+) (.+)/, 1]
      msg = str[/PRIVMSG \#\S+ \:\S+ (\S+) (.+)/, 2]
      if(!channel.nil? && !recv.nil? && !msg.nil?)
          @nags[recv.upcase] = "#{recv}, on #{Time.now} #{nick} created nag: #{msg}"
          say(bot, channel, "Successfully created nag")
          save
      end
  end

  def sendNag(bot, str)
      nick = str[/^:([^!]+)!/, 1]
      channel = str[/PRIVMSG (\#\S+)/, 1]
      if(!@nags[nick.upcase].nil?)
        say(bot, channel, @nags[nick.upcase])
        @nags[nick.upcase] = nil
        save
      end
  end

  def say(bot, chan, msg)
    bot.say(chan, "#{msg}#{@suffix}")

    if(@suffix.length == 0)
      @suffix = " "
    else
      @suffix = ""
    end
  end
end

m = Nag.new
CommandManager.add("", m.method(:sendNag))
CommandManager.add("!nag", m.method(:makeNag))
