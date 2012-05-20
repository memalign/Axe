#!/usr/bin/ruby

require "IrcBot"
require "ModLoader"

ModLoader.loadCore
ModLoader.loadModules("./modules/")

$address = "localhost"
#$address = "cornell.ashen.cc"
#$port = "6669"
$port = "55557"
$nickbase = "nehsA"
$pass = nil #"letmein"
#$pass = "letmein"
#$chans = ["\#thchub.no-ip.org:4000"] #, "\#pwnix"]
$chans = ["#thchub"]
$owner = "Ashen"

$socks = [];

def addConn
  puts "Adding connection."
  newbot = IrcBot.new($address, $port, $nickbase, $nickbase, $chans, $owner, $pass)
  #newbot.run
  $socks[$socks.length] = newbot
end

addConn #our first connection


$socks.each { |bot|
  bot.run
}

$socks.each { |bot|
  bot.joinT
}

