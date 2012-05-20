#!/usr/bin/ruby

require "IrcConn"
require "IrcParser"
require "ModLoader"
#require "./modules/CommandManager"

class IrcBot
  
  @@sleepconst = 0.01
  
  attr_reader :sock, :owner
  attr_writer :expectpong
  
  def initialize(addy, por, nic, usr, chans, ownr, pass=nil)
    @sock = IrcConn.new(addy, por, nic, usr, pass)
    @channels = chans
    @owner = ownr
    @expectpong = false
    @thr = nil
    @mutex = Mutex.new
    
    @throttlemutex = Mutex.new
    @throttlecondition = ConditionVariable.new
    @messagequeue = Array.new
    @secondcount = 0
    @linecount = 0
    @THROTTLELINES = 15 #20 is the real value, but i'm gonna give myself some leeway
    @THROTTLESECONDS = 10
  end
  
  def joinT
    @thr.join
    if(@pingthread != nil)
      @pingthread.join
    end
    if(@throttlethread != nil)
      @throttlethread.join
    end
  end

  def updateExpectpong(newval)
    @mutex.synchronize {
      @expectpong = newval
    }
  end
  
  def run
    @thr = Thread.new {
      #puts "Entering IO Loop"
      while(1)
        #puts "while"
        str = @sock.read
        if(str) #its not still trying to read
          print str
          IrcParser.process(self, str)
        end
        sleep(@@sleepconst)
      end
    }
    
    @pingthread = Thread.new {
      while(1)
        sleep(150)
        #puts "preping"
        @mutex.synchronize {
          if(@expectpong)
            #kill the old socket
            @sock.close
            #reconnect
            #initialize(@sock.address, @sock.port, @sock.nick, @sock.user, @channels, @owner, @sock.password)

            @sock = IrcConn.new(addy, por, nic, usr, pass)
            @expectpong = false
          else
            @expectpong = true
            @sock.write("PING :"+Time.now.to_i.to_s)        
          end
          #puts "PING :"+Time.now.to_i.to_s
          #puts "postping"
        }
      end
    }
    
    @throttlethread = Thread.new {
      #@secondcount
      #@linecount
      #@THROTTLELINES
      #@THROTTLESECONDS
      #@throttlemutex
      #@throttlecondition
      senttimes = Array.new
      
      while(1)
        @throttlemutex.synchronize {

          if(@messagequeue.length == 0)
            @throttlecondition.wait(@throttlemutex)
          end
          
          #clean up senttimes
          nowt = Time.now.to_i
          while(senttimes.length > 0 && nowt-senttimes[0] > @THROTTLESECONDS)
            senttimes.shift
          end
          
          #if there are lines and we can send, don't stop until we have to
          #this seems to be misbehaving, i just made a change to the second clause, test it first tomorrow
          while(senttimes.length < @THROTTLELINES && (senttimes.length == 0 || nowt-senttimes[0] <= @THROTTLESECONDS))
            mess = @messagequeue.shift
            if(mess != nil)
              senttimes.push(Time.now.to_i)
              @sock.write(mess)
            else
              #we ran out of lines
              break
            end
          end

          #we sent too many during the interval or ran out, we'll wait at the top of the loop
        }
        sleep(0.1)
      end
    }
  end
  
  def say(target, line)
    @throttlemutex.synchronize {
      @messagequeue.push("PRIVMSG #{target} :#{line}")
      @throttlecondition.signal
    }
    #@sock.write("PRIVMSG #{target} :#{line}")
  end

  def sendraw(str)
    @sock.write(str)
  end
  
  def gotmsg(str)
    #do nothing
    toks = str.split(" ", 4)
    hook = ""
    if(toks[3] =~ /^:(\S+)/)
      hook = $1
    end

    CommandManager.execCmd(self, hook, str)
    if(toks[0] =~ /^:#{@owner}!/)
      if(toks[3] =~ /^:!modload/)
        ModLoader.loadModules("./modules/")
      elsif(toks[3] =~ /^:!coreload/)
        ModLoader.loadCore
      end
    end
  end
  
  def doJoins
    @channels.each { |channel|
      @sock.write("JOIN #{channel}")
    }
  end

  def nick
    return @sock.nick
  end
  
  def appendToNick
    @sock.nick = @sock.nick+"_"
  end
  
  def protocolHooks(num, str)
    CommandManager.protocolHooks(self, num, str)
  end
end
