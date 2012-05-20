#!/usr/bin/ruby

class Message
attr_reader :msg, :date
    def initialize(msg, date)
        @msg = msg
        @date = date
    end
end

class Last 
  def initialize()
    @suffix = ""
    @users = Hash.new
    #read the data file 
    @@DBNAME = "./modules/last.txt" 
    IO.foreach(@@DBNAME) { |line|
        arr = line.split("\t",3)
        if(arr.length == 3)
            @users[arr[1]] = Message.new(arr[0], arr[2])
        end
    }
  end

  def save
    File.open(@@DBNAME, 'w') { |f|
        @users.keys.each { |u|
            f.write("#{@users[u].date}\t#{u}\t#{@users[u].msg}\n")
        }
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

    @users[nick.downcase] = Message.new(chatline.rstrip, Time.now.strftime("%c"))

    save
  end

  def getLast(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    channel = str[/PRIVMSG (\#\S+)/, 1]
    chatline = str[/ \:(.+)$/, 1]

    if(chatline != nil)
        other = chatline.split(" ")[1]
        if(@users[other.downcase])
            bot.say(channel, "Last seen: #{@users[other.downcase].date} <#{other}> #{@users[other.downcase].msg}#{@suffix}")
        else
            bot.say(channel, "Last seen: #{other} has never talked.#{@suffix}")
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
CommandManager.add("/seen", m.method(:getLast))
CommandManager.add("!seen", m.method(:getLast))
CommandManager.add("/last", m.method(:getLast))
CommandManager.add("!last", m.method(:getLast))

#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
