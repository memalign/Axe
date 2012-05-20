#!/usr/bin/ruby

class Last 
  def initialize()
    @suffix = ""
    @users = Hash.new
    #read the data file 
    @@DBNAME = "./modules/karma.txt" 
    IO.foreach(@@DBNAME) { |line|
        arr = line.split("\t",2)
        if(arr.length == 2)
            @users[arr[0]] = arr[1].to_i
        end
    }
  end

  def save
    File.open(@@DBNAME, 'w') { |f|
        @users.keys.each { |u|
            f.write("#{u}\t#{@users[u]}\n")
        }
        f.close
    }
  end
  
  def process(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    #:Ashen!~Ashen@albex PRIVMSG #thchub.no-ip.org:4000 :/roll 2d6
    channel = str[/PRIVMSG (\#\S+)/, 1]

    
    #seems to be a weird issue with my dc++ gateway
    if(channel == bot.nick || channel == "None")
        return
    end

    chatline = str[/ \:(.+)$/, 1]
    if(chatline.nil?)
        return
    end

    if(match = /([^\s\+]+)(\+\+|\-\-)/.match(chatline))
        if(match[1].downcase == nick.downcase)
            return
        end
        if(@users[match[1].downcase].nil?)
            @users[match[1].downcase] = 0
        end
        if(match[2] == "--")
            @users[match[1].downcase] = @users[match[1].downcase] - 1
        elsif(match[2] == "++")
            @users[match[1].downcase] = @users[match[1].downcase] + 1
        end
        @users["seventotheseven"] = 7
        bot.say(channel, "Karma for #{match[1]}: #{@users[match[1].downcase]}#{@suffix}")

        if(@suffix.length == 0)
          @suffix = " "
        else
          @suffix = ""
        end

    end

    save
  end

  def getKarma(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    channel = str[/PRIVMSG (\#\S+)/, 1]
    chatline = str[/ \:(.+)$/, 1]

    if(chatline != nil)
        other = chatline.split(" ")[1]
        if(!other.nil? && @users[other.downcase])
            bot.say(channel, "Karma for #{other}: #{@users[other.downcase]}#{@suffix}")
        else
            bot.say(channel, "Karma for #{other}: 0")
        end
    end

    if(@suffix.length == 0)
      @suffix = " "
    else
      @suffix = ""
    end

  end
end

m = Last.new
CommandManager.add("", m.method(:process))
CommandManager.add("/karma", m.method(:getKarma))
CommandManager.add("!karma", m.method(:getKarma))

#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
