#!/usr/bin/ruby
require "socket"
require 'thread'

class IrcConn
  attr_reader :address, :port, :nick, :user, :password
  attr_writer :nick

  #each IrcConn needs its own socket
  def initialize(addy, p, nic, usr, pass=nil)
    @reading = nil
    @address = addy
    @port = p
    @nick = nic
    @user = usr
    @password = pass
    #@sock = TCPSocket.open(@address, @port)
    
    addr = Socket.getaddrinfo(@address, nil)
    @sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)
    #setup our timeout
    @@TIMEOUT = 20
    secs = Integer(@@TIMEOUT)
    usecs = Integer((@@TIMEOUT-secs)*1_000_000)
    optval = [secs, usecs].pack("l_2")
    @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
    @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval

    tryagain = true 
    while(tryagain)
        begin
          @sock.connect(Socket.pack_sockaddr_in(port, addr[0][3]))
          tryagain = false
        rescue
          puts "Connection failed, trying in a few seconds..."
          sleep(5)
          tryagain = true
        end
    end

    write "USER #{@user} . . :#{@nick}"
    write "NICK #{@nick}"
    if(pass)
      write "PASS #{@password}"
    end
    @mutex = Mutex.new
  end
  
  #it needs a read function
  def read
    @mutex.synchronize {
      if(!@reading)
        @reading = 1
        begin
            str = @sock.gets
        rescue
        end

        @reading = nil
        return str
      else
        return nil
      end
    }
  end

  #it needs a write function
  def write(line)
      begin
        @sock.puts line
      rescue
      end
    puts ">> #{line}"
  end
  
  def close
    #@sock.shutdown(2)
    begin
      @sock.close
    rescue
    end
  end
end
