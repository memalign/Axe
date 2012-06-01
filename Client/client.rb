#!/usr/bin/ruby

$: << "/Library/Ruby/Gems/1.8/gems/ncurses-0.9.1/lib/"
$: << "./Client"
$: << "."
$: << ".."

require "ncurses"
require "IrcClientParser.rb"
require "ecma48sgr.rb"
include Ncurses
include ECMA48SGR

class WindowManager
  def initialize
    @array = Array.new
    @nextwinpos = 0
  end
  
  def getArray
    @array
  end
  
  def getOrderedWindows
    arr = Array.new
    @array.each { |ic|
      ic.getWindows.each { |w|
        arr.push(w)
      }
    }
    
    arr.sort! { |a, b|
      a.position <=> b.position
    }
    return arr
  end
  
  def nextWindowPosition
    a = @nextwinpos
    @nextwinpos += 1
    return a
  end
  
  def addWindow(win, irc=nil)
    if(!irc.nil?)
      for ic in @array
        if(ic.irc == irc)
          ic.addWindow(win)
          break
        end
      end
    else
      ic = IrcContainer.new
      ic.addWindow(win)
      @array.push(ic)
    end
  end
  
  def getWindow(irc, target)
    for ic in @array
      if(ic.irc == irc)
        for w in ic.getWindows.reverse
         # w.c.put(0, 29, "Len: "+ic.getWindows.length.to_s)
         # w.c.put(0, 28, "id: "+w.id.to_s)
         # w.c.put(0, 27, "Chan: "+w.channel.to_s+" T: "+target.to_s)
          if(w.channel.to_s.casecmp(target.to_s) == 0)
            return w
          end
        end
      end
    end
  end
  
  def getIrcWindows(irc)
    for ic in @array
      if(ic.irc == irc)
        return ic.getWindows
      end
    end
  end
  
  def setIrc(window, irc)
    #myIc = @array.find { |ic|
    #  ic.windows.find { |w|
    #    w.channel.casecmp(window.channel)
    #  }.nil? == false
    #}
    #window.c.put(0, 21, "beginfunc")
    myIc = nil
    for ic in @array
      #  window.c.put(0, 24, "in loop 1")
      for w in ic.getWindows
        #w.c.put(15, 20, "in loop 2")
        if(w.id == window.id)
         # window.c.put(0, 22, "found it!")
          myIc = ic
          break
        end
      end
    end
    #window.c.put(0, 23, "all done!")
    myIc.closeIrc("Changing Servers")
    myIc.irc = irc
  end
  
  def removeWindow(window)
    myIc = nil
    for ic in @array
      for w in ic.getWindows
        if(w.id == window.id)
          myIc = ic
          break
        end
      end
    end
    myIc.removeWindow(window)
  end
  
  def getIrc(window)
    for ic in @array
      #  window.c.put(0, 24, "in loop 1")
      for w in ic.getWindows
        #w.c.put(15, 20, "in loop 2")
        if(w.id == window.id)
         # window.c.put(0, 22, "found it!")
          return ic.irc
        end
      end
    end
  end
end

class IrcContainer
  @@idcount = 0
  
  attr_writer :irc
  attr_reader :irc
  
  def initialize(myIrc=nil)
    @id = @@idcount
    @@idcount += 1
    @irc = myIrc
    @windows = Array.new
  end
  
  def addWindow(win)
    @windows.push(win)
  end
  
  def removeWindow(win)
    @windows = @windows.delete_if { |w|
      w.id == win.id
    }
  end
  
  def closeIrc(str)
    if(!@irc.nil?)
      @irc.quit(str)
    end
  end
  
  def getWindows
    @windows
  end
  
end

class UserCommandParser
  @@cmd = { }
  
  def UserCommandParser.add(hook, cmdref)
    @@cmd[hook] = cmdref
  end

  def UserCommandParser.del(hook)
    @@cmd[hook] = nil
  end

  def UserCommandParser.parse(client, str)
    hook = (str.split(" "))[0]
    if(@@cmd[hook])
      @@cmd[hook].call(client, str)
    else
      #defaultcmd(client, str)
    end
  end
  
end

class ClientCommandParser < UserCommandParser
  def initialize
    UserCommandParser.add("/server", self.method(:server))
    UserCommandParser.add("/quit", self.method(:quit))
    UserCommandParser.add("/window", self.method(:window))
  end
  
  def parse(client, str)
    hook = (str.split(" "))[0]
    if(@@cmd[hook])
      @@cmd[hook].call(client, str)
    else
      defaultcmd(client, str)
    end
  end
  
  def defaultcmd(client, str)
    if(str[0].chr.to_s == "/")
      client.raise(0, client.windowmanager.getIrc(client.currentwindow), [str[1, str.length-1]])
    else
      #client.raise(0, client.currentwindow, [
      #implement privmsg
      if(client.currentwindow.channel != 0 && client.windowmanager.getIrc(client.currentwindow))
        client.raise(0, client.windowmanager.getIrc(client.currentwindow), ["PRIVMSG "+client.currentwindow.channel.to_s+" :"+str])
        client.raise(1, nil, [client.currentwindow, "<"+client.windowmanager.getIrc(client.currentwindow).nick.to_s+"> "+ str])
      else
        client.raise(1, nil, [client.currentwindow, "Pick a channel first"])
      end
    end
  end
  
  def server(client, str)
    args = str.split(" ")
    client.raise(1, nil, [client.windowmanager.getWindow(client.windowmanager.getIrc(client.currentwindow), 0), "Connecting to #{args[1]}:#{args[2]}"])
    Thread.new {
      client.currentwindow.makeConn(args[1], args[2].to_i, "Axe", "axe")
    }
  end
  
  def window(client, str)
    args = str.split(" ")
    case args[1]
      when "file":
        dims = [1, 16, 26, 25]#window.getDimensions
        if(args.length == 7)
          dims = [args[3].to_i, args[4].to_i, args[5].to_i, args[6].to_i]
        end
        client.addWin(nil, CursesTailWindow.new(args[2],dims[0],dims[1],dims[2],dims[3], client))
      when "close":
        win = client.currentwindow
        client.currentwindow = nil
        client.windowmanager.removeWindow(win)
        client.draw
      when "save":
        file = "./rubywindows.conf"
        if(args.length > 2)
          file = args[2]
        end
        out = File.new(file, "w")
        client.windowmanager.getOrderedWindows.each { |win|
          if(!client.windowmanager.getIrc(win) && win.channel && win.channel != 0)
            out.puts("/window file #{win.channel} #{win.xtop} #{win.ytop} #{win.xbottom} #{win.ybottom}")
          end
        }
        out.close
      when "load":
        file = "./rubywindows.conf"
        if(args.length > 2)
          file = args[2]
        end
        if(File.exists?(file))
          inf = File.new(file, "r")
          inf.readlines.each { |line|
            if(line =~ /^\/window/)
              parse(client, line)
            end
          }
          inf.close
        end
    end
  end
  
  def quit(client, str)
    client.cleanup
    exit
  end
end

class Toolbar
  def initialize
    #do nothing
  end
  
  def to_s
    ""
  end
end

class TopicToolbar < Toolbar
  def initialize(str="")
    @topic = str
    @active = true
  end
  
  def active
    @active
  end
  
  def topic(str="")
    @topic = str
  end
  
  def toggle
    @active = !@active
  end
  
  def to_s
    @topic
  end
end

class InputToolbar < Toolbar
  def initialize(c)
    @prompt = "> "
    @userlineb = ""
    @userlinea = ""
    @client = c
    @parser = ClientCommandParser.new
    @mode = 0 # normal input
    @client.draw
  end
  
  def to_arr
    [@prompt + @userlineb, @userlinea]
  end
  
  def process(ch)
    @prompt = "[#{ch.to_s.ljust(3)}]> "
    case (@mode)
      when 0:
        case (ch)
          when 10:
            if((@userlineb+@userlinea).length > 0)
              sendline(@userlineb+@userlinea)
            end
            @userlineb = ""
            @userlinea = ""
          when 14: #next
            #switch windows
            #ordered by position
            oldwin = @client.currentwindow
            wins = @client.windowmanager.getOrderedWindows
            pos = @client.currentwindow.position
            @client.currentwindow = wins[0]
            for w in wins
              if(w.position > pos)
                @client.currentwindow = w
                break
              end
            end
            oldwin.draw
            @client.currentwindow.draw(true)
          when 16: #prev
            oldwin = @client.currentwindow
            wins = @client.windowmanager.getOrderedWindows.reverse
            pos = @client.currentwindow.position
            @client.currentwindow = wins[0]
            for w in wins
              if(w.position < pos)
                @client.currentwindow = w
                break
              end
            end
            oldwin.draw
            @client.currentwindow.draw(true)
          when 18: #ctrl+r
            @mode = 2
            @client.draw
          when 23: #ctrl+w
            @mode = 1
            @client.draw
          when 127, 263:
            @userlineb.chop!
          when 260: #left
            if(@userlineb.length > 0)
              c = @userlineb[@userlineb.length-1]
              @userlineb = @userlineb[0,@userlineb.length-1]
              @userlinea = c.chr.to_s + @userlinea
            end
          when 261: #right
            if(@userlinea.length > 0)
              c = @userlinea[0]
              @userlineb = @userlineb + c.chr.to_s
              @userlinea = @userlinea[1, @userlinea.length-1]
            end
          when 330:
            if(@userlinea.length > 0)
              @userlinea = @userlinea[1, @userlinea.length-1]
            end
          else
            if(ch < 255)
              @userlineb += ch.chr.to_s
            end
        end
      when 1: #move mode
        case(ch)
          when 259: #up
            @client.currentwindow.decy
          when 258: #down
            @client.currentwindow.incy
          when 260: #left
            @client.currentwindow.decx
          when 261: #right
            @client.currentwindow.incx
          when 23: #end move mode
            @mode = 0
            @client.draw
        end
        @client.clearwindow
        @client.draw
      when 2:
        case(ch)
          when 18:
            @mode = 0
            @client.draw
          when 259: #up
            @client.currentwindow.shrinky
          when 258: #down
            @client.currentwindow.growy
          when 260: #left
            @client.currentwindow.shrinkx
          when 261: #right
            @client.currentwindow.growx
        end
        @client.clearwindow
        @client.draw
    end
  end
  
  def sendline(str="")
    #if(str == "quit")
    #  @client.cleanup
    #  exit
    #if(str == "conn")
    #  @client.currentwindow.makeConn("meatmanek.ath.cx", 6667, "Axe", "axe")
    #end
    @parser.parse(@client, str)
    #@client.raise(1, @client.currentwindow, [str])
  end
  
end

class Window
  attr_reader :c, :id, :channel, :xtop, :ytop, :xbottom, :ybottom
  @@idcount = 0
  def initialize(cl, xt=0, yt=0, xb=0, yb=0)
    @xtop = xt
    @ytop = yt
    @xbottom = xb
    @ybottom = yb
    @buffer = Array.new
    @toolbars = Array.new
    @c = cl
    @id = @@idcount
    @@idcount += 1
    @channel = 0
  end
  
  def getDimensions
    [@xtop, @ytop, @xbottom, @ybottom]
  end
  
  #def buffSize
    #implement me in a child class
  #end
  
  def addline(str, len)
    #@buffer.push(str.to_s.ljust(@xbottom-@xtop+1, " "))
    @buffer.push(str.to_s)
    if(@buffer.length > len)
      @buffer.shift
    end
  end
  
  def draw
   #this should be defined in child classes
  end

  def makeConn(addy, port, nick, user, pass=nil)
    t = IrcConn.new(addy, port, nick, user, pass)
    @c.windowmanager.setIrc(self, t)
  end

end

class CursesWindow < Window
  attr_reader :position

  def initialize(sc=nil,xt=0, yt=0, xb=0, yb=0)
    super(sc, xt, yt, xb, yb)
    #@c = sc #client

    @topicbar = TopicToolbar.new("Topic bar")
    buffSize.times{ |n|
      addline("", buffSize)
    }
    
    @position = sc.windowmanager.nextWindowPosition
  end
  
  def incy
    @ytop += 1
    @ybottom += 1
  end
  
  def decy
    @ytop -= 1
    @ybottom -= 1
  end
  
  def incx
    @xtop += 1
    @xbottom += 1
  end
  
  def decx
    @xtop -= 1
    @xbottom -= 1
  end
  
  def shrinky
    if(@ybottom-@ytop > 0)
      @ybottom -= 1
    end
  end
  
  def growy
    @ybottom += 1
  end
  
  def shrinkx
    if(@xbottom-@xtop > 0)
      @xbottom -= 1
    end
  end
  
  def growx
    @xbottom += 1
  end
  
  def buffSize
    #ret = @ybottom-@ytop+1
    #if(@topicbar.active)
    #  ret -= 1
    #end
    #return ret
    1000
  end
  
  def draw(active=false)
    border = 3 #sleepy border
    if(active)
      #active border
      border = 2
    end
    offset = 0
    if(@topicbar.active)
      str = @topicbar.to_s.ljust(@xbottom-@xtop+1)
      if(str.length > @xbottom-@xtop+1)
        str = str[0, @xbottom-@xtop+1]
      end
      if(str)
        @c.put(@xtop-1, @ytop+offset, " ", border)
        @c.put(@xtop, @ytop+offset, str, 2) #color pair is last
        @c.put(@xtop+str.length, @ytop+offset, " ", border)
      end
      offset += 1
    end
    i = 0
    #@buffer.each_index { |i|
    @printbuff = Array.new
    @buffer[(@buffer.length-(@ybottom-@ytop))-1..@buffer.length-1].each { |str| #|i|
      nickpad = 0
      if(str =~ /^(\[\d{2}:\d{2}:\d{2}\] \<.[^\>]+\> )/ || str =~ /^(\[\d{2}:\d{2}:\d{2}\] (?:\* \S+|\-\!\-) )/)
        ar = str.split(" ")
        biggest = 0
        ar.each { |ls|
          if(ls.length > biggest)
            biggest = ls.length
          end
        }
        nickpad = $1.length
        if(nickpad >= @xbottom-@xtop-biggest)
          nickpad = 0
        end
      end
      noffset = 0
      #str = @buffer[i]
      while(!str.nil?)
        #@c.put(27, 22, str)
        cut = -1
        first = -1
        if(str.length > @xbottom-@xtop+1)
          cut = str[0, @xbottom-@xtop+1].rindex(" ")
          first = str[0, @xbottom-@xtop+1].index(" ")
          if(!first || first < 0)
            first = 0
          end
        end
        if(cut.nil?)
          cut = -1
        end
        toprint = ""
        if(cut > first && cut < @xbottom-@xtop+1)
          #@c.put(0, 29, cut.to_s)
          toprint = str[0..cut]
          str = str[cut+1..str.length-1].to_s
          str = str.rjust(str.length+nickpad)
        else
          if(str.length-1 <= @xbottom-@xtop)
            toprint = str
            str = nil
          else
            toprint = str[0..@xbottom-@xtop]
            str = str[@xbottom-@xtop+1..str.length-1].to_s
            str = str.rjust(str.length+nickpad)
          end
        end
        #if(@ytop+i+offset <= @ybottom)
          #@c.put(@xtop, @ytop+i+offset, toprint.ljust(@xbottom-@xtop+1))
          @printbuff.push(toprint.ljust(@xbottom-@xtop+1, " "))
          if(str.nil? || str.length == 0)
            str = nil
          else
            noffset += 1
          end
        #end
      end
      i += 1
    }
    i = 0
    s = @printbuff.length-(@ybottom-@ytop)
    if(s < 0)
      s = 0
    end
    @printbuff[s..@printbuff.length-1].each { |str|
      #@c.put(@xtop, @ytop+i+offset, str[0,1], border)
      @c.put(@xtop-1, @ytop+i+offset, " ", border)
      
      #CRAPPY CUSTOM COLOR CODES START HERE
      place = 0
      if(str =~ /^\[(\d{2}):(\d{2}):(\d{2})\]/)
        #@c.scr.attron(@c.scr.COLOR_PAIR(@c.colors['red']))
        @c.put(@xtop,@ytop+i+offset, "[", @c.colors['red'])
        place += 1
        @c.put(@xtop+place, @ytop+i+offset, $1)
        place += $1.length
        @c.put(@xtop+place, @ytop+i+offset, ":")
        place += 1
        @c.put(@xtop+place, @ytop+i+offset, "#$2")
        place += $2.length
        @c.put(@xtop+place, @ytop+i+offset, ":")
        place += 1
        @c.put(@xtop+place, @ytop+i+offset, "#$3")
        place += $3.length
        @c.put(@xtop+place, @ytop+i+offset, "]", @c.colors['red'])
        place += 1
        #@c.scr.attroff(@c.scr.COLOR_PAIR(@c.colors['red']))
        str = str[place..str.length]
      end #, "#{Fg['black']}[\1:\2:\3\]#{Fg['std']}")
      if(str =~ /^ \<(.)([^\>]+)\>/)
        oplace = place
        @c.put(@xtop+place, @ytop+i+offset, " ")
        place += 1
        @c.put(@xtop+place, @ytop+i+offset, "<#$1", @c.colors['blue'])
        place += 2
        @c.put(@xtop+place, @ytop+i+offset, $2)
        place += $2.length
        @c.put(@xtop+place, @ytop+i+offset, ">", @c.colors['blue'])
        place += 1
        str = str[place-oplace..str.length]
      end
      #CRAPPY CUSTOM COLOR CODES END HERE
      
      @c.put(@xtop+place, @ytop+i+offset, str)
      @c.put(@xtop+str.length+place, @ytop+i+offset, " ", border)
      #@c.put(@xtop+str.length-1, @ytop+i+offset, str[str.length-1, 1], border)
      i += 1
    }
    @c.put(@xtop-1,@ybottom+1, "".ljust(@xbottom-@xtop+3, " "), border)
    if(self != @c.currentwindow)
      @c.currentwindow.draw(true)
    end
    @c.drawInputBar
  end
end

class CursesTailWindow < CursesWindow
  attr_reader :topic, :topicsetter, :channel
  attr_writer :topic, :topicsetter
  
  @@ids = [ ]
  
  def initialize(file, xt=0, yt=0, xb=0, yb=0, sc=nil)
    super(sc, xt, yt, xb, yb)
    @topicsetter = ""
    @channel = file
    parts = file.split("/")
    self.topic = parts[-1]
    t = Thread.new("tail -f #{file}") { |cmd|
      io = IO.popen(cmd)
      tid = io.pid
      @@ids << tid
      io.each { |line|
        if(sc)
          line = self.parse(line)
          sc.raise(2, nil, [@channel, line])
          draw
        end
      }
      @@ids.delete_if { |x|
        x == tid
      }
    }
  end
  
  #NOTE: This is kinda specific to my irssi log configuration. I really need to make it work for everyone
  def parse(line)
    toks = line.split(" ", 5)
    timestamp = toks[3]
    message = toks[4]
    
    timestamp = "[#{timestamp}]"
    #if(message =~ /^(\<.[^\>]\>) (.+)$/)
    #  timestamp = "#{timestamp} #$1"
    #  message = $2
    #end
    "#{timestamp} #{message}"
  end
  
  def irc
    nil
  end
  
  def CursesWindow.GetIds
    @@ids
  end
  
  def topic=(str)
    @topicbar.topic(str)
  end

end

class CursesChannelWindow < CursesWindow
  attr_reader :topic, :topicsetter
  attr_writer :topic, :topicsetter

  def initialize(chan, xt=0, yt=0, xb=0, yb=0, sc=nil)
    super(sc, xt, yt, xb, yb)
    @channel = chan
    @topicsetter = ""
  end
  
  def getChannel
    @channel
  end
  
  def topic=(str)
    @topicbar.topic(str)
  end
  
end

class Client

  attr_reader :currentwindow, :windowmanager, :colors, :scr
  attr_writer :currentwindow

  def initialize
    @scr = Ncurses.initscr
    @row = Array.new
    @col = Array.new
    @scr.getmaxyx(@row, @col)
    #put(0,0, "ROW: #{@row[0]} COL #{@col[0]}")
    Ncurses.start_color
    Ncurses.noecho
    Ncurses.halfdelay(1)
    Ncurses.keypad(@scr, true)
    Ncurses.init_pair(1, 7, 0)
    Ncurses.init_pair(2, 7, 4)
    Ncurses.init_pair(3, 0, 7)
    @colors = { }
    @colors['black'] = 11
    @colors['red'] = 4
    @colors['green'] = 5
    @colors['yellow'] = 6
    @colors['blue'] = 7
    @colors['cyan'] = 8
    @colors['magenta'] = 9
    @colors['white'] = 10
    Ncurses.init_pair(4, 1,    0);
    Ncurses.init_pair(5, 2,   0);
    Ncurses.init_pair(6, 3,  0);
    Ncurses.init_pair(7, 4,    0);
    Ncurses.init_pair(8, 6,    0);
    Ncurses.init_pair(9, 5, 0);
    Ncurses.init_pair(10, 7,   0);
    Ncurses.init_pair(11, 0, 0);
    @windowmanager = WindowManager.new
    #@windows = Array.new
    #@windows.push(CursesWindow.new(self, 0, 0, @col[0]-1, @row[0]-2))
    @currentwindow = CursesWindow.new(self, 2, 5, @col[0]-1, 10)
    @windowmanager.addWindow(@currentwindow)
    #@windows.push(CursesWindow.new(self, 15, 15, 25, 25))
    @inputbar = InputToolbar.new(self)
    draw
  end
  
  def addWin(irc,window)
    @windowmanager.addWindow(window, irc)
    @currentwindow = window
  end
  
  def checkResize
    r = Array.new
    c = Array.new
    Ncurses.getmaxyx(@scr, r, c)
    if((r[0] != @row[0]) || (c[0] != @col[0]))
      @row = r
      @col = c
      clearwindow
      draw
    end
    @scr.refresh
  end
  
  def draw
    #put(0,26,"C: "+(@windowmanager.getArray)[0].getWindows.length.to_s)
    @windowmanager.getArray.each { |ic|
      ic.getWindows.each { |w|
        if(w != @currentwindow)
          w.draw
        end
      }
    }
    
    if(@currentwindow)
      @currentwindow.draw(true)
    end
    #put(0, @row[0]-1, "".ljust(@col[0]))
    #arr = @inputbar.to_arr
    #put(arr[0].length, @row[0]-1, arr[1])
    #put(0, @row[0]-1, arr[0])
    #@scr.refresh
    drawInputBar
  end
  
  def drawInputBar
    put(0, @row[0]-1, "".ljust(@col[0]))
    if(@inputbar)
      arr = @inputbar.to_arr
      put(arr[0].length, @row[0]-1, arr[1])
      put(0, @row[0]-1, arr[0])
    end
    @scr.refresh
  end
  
  def clearwindow
    (@row[0]-1).times { |i|
      put(0, i, "".ljust(@col[0]))
    }
  end
  
  def put(x=0,y=0,str="", colorpair=1)
    if(y >= 0 && y <= @row[0])
      @scr.attron(Ncurses.COLOR_PAIR(colorpair))
      #@scr.mvprintw(y,x,str)
      sx = 0
      ex = str.length-1
      if(x < 0)
        sx = x.abs
        x = 0
      end
      if(x+str.length > @col[0])
        ex = @col[0]-x-1+sx
      end
      if(sx <= ex && !str[sx..ex].nil?)
        @scr.mvaddstr(y,x,str[sx..ex])
      end
      @scr.attroff(Ncurses.COLOR_PAIR(1))
      @scr.refresh
    end
  end

  def raise(sig, irc, args)
    #codes are as follows:
    # 0 - message to be sent to socket
    # 1 - message to be sent to client
    # 2 - message sent to a target window
    # 3 - message sent to all windows for an irc
    # 4 - topic change for a given target
    case(sig)
      when 0:
        #if(@windowmanager.getIrc(window))
        #  @windowmanager.getIrc(window).write(args[0])
        #end
        if(irc)
          irc.write(args[0])
        end
      when 1:
        win = args[0]
        win.addline(args[1].chomp, win.buffSize)
        win.draw
      when 2:
        #put(0, 27, "Target: "+args[0].to_s)
        win = @windowmanager.getWindow(irc, args[0].to_s)
        #put(0, 27, "win: "+win.to_s)
        win.addline(args[1].chomp, win.buffSize)
        win.draw
      when 3:
        @windowmanager.getIrcWindows(irc).each { |w|
          w.addline(args[0].chomp, w.buffSize)
          w.draw
        }
      when 4:
        win = @windowmanager.getWindow(irc, args[0].to_s)
        win.topic = args[1].to_s.chomp
        win.topicsetter = args[2].to_s
        win.draw
    end
  end
  
  def cleanup
    ids = CursesTailWindow.GetIds
    ids.each { |id|
      Kernel.system("kill #{id}")
    }
    Ncurses.endwin
  end
  
  def getc
    @scr.getch
  end
  
  def doUserIO
    ch = getc
     if(ch != -1)
      #if(ch <= 255 && ch.chr.to_s == "q")
      #  cleanup
      #  exit
      #end
      @inputbar.process(ch)
      drawInputBar
      #put(0,0,@inputbar.to_s)#@userline)
    end
  end
  
  def doNetIO
    #put(0,20,"C: "+(@windowmanager.getArray)[0].irc.nil?.to_s)
    @windowmanager.getArray.each { |ic|
      irc = ic.irc
      if(!irc.nil?)
    #@windows.each { |w|
    #  irc = w.getIrc
        Thread.new {
          str = irc.read
          if(str)
            IrcClientParser.process(self, irc, str)
            #draw
          end
        }
      end
    }
  end
  
end

c = Client.new
while true
  c.doUserIO
  c.doNetIO
  c.checkResize
  #c.draw
  sleep(0.001)
end
