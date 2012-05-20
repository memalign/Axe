#!/usr/bin/ruby

#require "CommandManager"

class Items
  def initialize(str)
    if(str == nil)
      str = ""
    end
    levels = str.split(",")
    for i in (0..4)
      if(levels[i] == nil)
        levels[i] = 0
      end
    end
    @armor = levels[0].to_i
    @weapon1 = levels[1].to_i
    @weapon2 = levels[2].to_i
    @strategy = levels[3].to_i
    @strength = levels[4].to_i
  end

  def list
    return [@armor, @weapon1, @weapon2, @strategy, @strength]
  end

  def tryUpgrade(pick, points)
    #I got 770 words per day on average based on the average words per day of the top 3 + ranks22,23,24
    @@AVGWORDS = 770

    if(pick == 0) 
      val = 2*(@armor+1)*@@AVGWORDS
      if(points > val)
        @armor = @armor + 1
        return val
      end
    elsif(pick == 1)
      val = 2*(@weapon1+1)*@@AVGWORDS
      if(points > val)
        @weapon1 = @weapon1 + 1
        return val
      end
    elsif(pick == 2)
      val = 2*(@weapon2+1)*@@AVGWORDS
      if(points > val)
        @weapon2 = @weapon2 + 1
        return val
      end
    elsif(pick == 3)
      val = 2*(@strategy+1)*@@AVGWORDS
      if(points > val)
        @strategy = @strategy + 1
        return val
      end
    elsif(pick == 4)
      val =  2*(@strength+1)*@@AVGWORDS
      if(points > val)
        @strength = @strength + 1
        return val
      end
    end
    return 0    
  end

  def upgradeRequest(wordpts, karma, penalty)
    #pick one of the various attributes at random
    pick = rand(5)
    ret = tryUpgrade(pick, wordpts+karma-penalty)
    if(ret != 0)
      #woo it worked
      return ret
    else
      #let's try the next one...
      pick = (pick+1) % 5
      return tryUpgrade(pick, wordpts+karma-penalty)
    end
  end
  
  def toEntry
    ret = "#{@armor},#{@weapon1},#{@weapon2},#{@strategy},#{@strength}"
    return ret
  end
  
  def min(a, b)
    if(a < b)
      return a
    else
      return b
    end
  end
  
  def toString
    @@ARMORS = ["Peasant Clothing", "Deer Leather Armor", "Plate Armor", "Bronze Chainmail", "Black Steel Chainmail", "Mithril Chainmail"]
    @@WEAPONS1 = ["Wood Spear", "Trident", "Wood Bow+Arrows", "Potato Launcher", "Throwing Axe", "Arbalest Crossbow", "Dagger", "Sting Sword", "Excalibur Sword", "Sword of Arwin", "Lightsaber", "Sword of Power and Doom"]
    @@WEAPONS2 = ["Club", "Board with a Nail", "Blackjack", "Flail", "Morning Star", "Baseball Bat", "Maul Hammer", "War Scythe"]
    
    arm = min(@armor, @@ARMORS.length-1)
    wea1 = min(@weapon1, @@WEAPONS1.length-1)
    wea2 = min(@weapon2, @@WEAPONS2.length-1)
    
    ret = "wearing [#{@@ARMORS[arm]}], fighting with a [#{@@WEAPONS1[wea1]}] in one hand a [#{@@WEAPONS2[wea2]}] in the other."
    ret << " Strength = #{@strength}, Strategy = #{@strategy}"
    return ret
  end
end

class User
  def initialize(str)
    @yespm = 0 #0 is none
               #1 is personal PMs
               #2 is all public PMs
    
    @lastnotice = nil
    @oldspam = true

    @here = false
    
    fields = str.split("\t")  
    @names = fields[0].split("!")
    @wordpoints = fields[1].to_i
    @penalty = fields[2].to_i
    @karma = fields[3].to_i
    @yespm = fields[4].to_i
    @items = Items.new(fields[5])
    
    @day = Time.now.day
    @wordstoday = 0
    @upgradedtoday = false
    @battlestoday = 0
    @UPGRADETHRESHOLD = 100 #after this many words in a day, we can ask for an upgrade
    @BATTLETHRESHOLD = 200
    
    @SPAMLEVEL = 5 # keep a history of this many lines
    @spamindex = 0
    @lastwordcounts = Array.new
    @lastlinetimes = Array.new
    (0..@SPAMLEVEL-1).each { |x|
      @lastwordcounts[x] = 0
      @lastlinetimes[x] = 0
    }
  end

  def markHere
    @here = true
  end
  
  def markGone
    @here = false
  end

  def isHere
    return @here
  end

  def enablePM
    @yespm = 1
  end
  
  def enableAllPM
    @yespm = 2
  end

  def disablePM
    @yespm = 0
  end

  def toString
    ret = ""
    ret << @names[0]
    ret << " points="
    ret << @wordpoints.to_s
    ret << " penalties="
    ret << @penalty.to_s
    ret << " karma="
    ret << @karma.to_s
    ret << " items: "
    ret << @items.toString
    ret << "; Rankpoints = #{rankpoints}"
  end
  
  def penalize
    @penalty += 5
  end
  
  def checkSpam
    newspam = true
    if(@lastlinetimes[@SPAMLEVEL-1] == 0)
      newspam = true
    else
      #spam means:
      #all of the lines came within a certain amount of time
      t0 = @lastlinetimes[@spamindex]
      idx = @spamindex-1
      if(idx < 0)
        idx += @spamindex-1
      end
      
      if(@lastwordcounts[idx] > 40) #line is too long! spam
        newspam = true
      else
        t1 = @lastlinetimes[idx]
        newspam = ((t1-t0) > 10)
      end
    end
    
    if(newspam && newspam != @oldspam)
      #@lastnotice << "Stop spamming, #{@names[0]}!! "
    end
    
    @oldspam = newspam
    
    return newspam
  end
  
  def battle(opponent)
    #compare items, winner of the most items, wins the battle
    #loser gets penalized 10% of their wordpoints
    #winner gets an extra 20% of their wordpoints
    ours = itemList
    if(opponent.nil?)
      return ""
    end
    theirs = opponent.itemList
    wins = 0
    for i in (0..ours.length-1)
      if(rand(4*ours[i]+1) >= rand(4*theirs[i]+1))
        wins = wins+1
      end
    end
      
    if(wins > ours.length/2)
      wonBattle(opponent)
      opponent.lostBattle
      return "#{@names[0]} challenged #{opponent.allnames[0]} and won!"
    else
      lostBattle
      opponent.wonBattle(self)
      return "#{@names[0]} challenged #{opponent.allnames[0]} and lost!"
    end
  end

  def rankpoints
    aval = 0
    itemList.each { |x|
      aval = aval + x
    }

    return aval*100000+@wordpoints+@karma-@penalty
  end
  
  def getWordpoints
    return @wordpoints
  end
  
  def lostBattle
    @wordpoints -= (@wordpoints*0.1).to_i
  end
  
  def wonBattle(opp)
    @wordpoints += (opp.getWordpoints*0.2).to_i
  end
  
  def itemList
    return @items.list
  end
  
  def addLine(length, opponent)
    @lastnotice = ""
    
    @lastwordcounts[@spamindex] = length
    @lastlinetimes[@spamindex] = Time.now.to_i
    @spamindex = (@spamindex+1) % @SPAMLEVEL
    
    if(Time.now.day != @day)
      @wordstoday = 0
      @upgradedtoday = false
      @battlestoday = 0
      @penalty = (4*@penalty)/5
      @day = Time.now.day
    elsif(checkSpam)
      @wordstoday += length
      if(!@upgradedtoday && @wordstoday > @UPGRADETHRESHOLD)
        #ask for an upgrade!
        @upgradedtoday = true
        ret = @items.upgradeRequest(@wordpoints, @karma, @penalty)        
        @wordpoints -= ret # 0 if failed, positive cost if succeeded
        if(ret != 0)
          @lastnotice << "#{@names[0]} successfully upgraded an attribute! "
        end
      end
      
      if(@wordstoday > (@battlestoday+1)*@BATTLETHRESHOLD)
        #woo battletime!
        @battlestoday = @battlestoday+1
        battleout = battle(opponent)
        @lastnotice << "#{battleout} "
      end
    end
  
    if(checkSpam)
      @wordpoints += length
    else
      @penalty += 5
    end
    
    if(@lastnotice == "")
      @lastnotice = nil
    end
  end
  
  def addUrl
    if(checkSpam)
      @wordpoints += 5
    end
  end
  
  def addImage
    if(checkSpam)
      @wordpoints += 5
    end
  end
  
  def addYoutube
    if(checkSpam)
      @wordpoints += 2
    end
  end
  
  def toEntry
    ret = ""
    comma = ""
    @names.each { |name|
      ret << "#{comma}#{name}"
      comma = "!"
    }
    ret << "\t"
    ret << @wordpoints.to_s
    ret << "\t"
    ret << @penalty.to_s
    ret << "\t"
    ret << @karma.to_s
    ret << "\t"
    ret << @yespm.to_s
    ret << "\t"
    ret << @items.toEntry
    return ret
  end
  
  def allnames()
    return @names
  end
  
  def lastNotice
    return @lastnotice
  end

  def wantspm
    return @yespm
  end

end


class HubRPG
  @@bot = nil
  @@target = ""


  def initialize()
    @spacestr = ""
    
    #load up the database
    @users = { }
    @uniquelist = { }
    @@DBFILE = "./modules/hubdata.txt"
    IO.foreach(@@DBFILE) { |line|
      #puts "read #{line}"
      if(line.split("\t").length > 3)
        tuser = User.new(line)
        @uniquelist[tuser.allnames[0]] = tuser
        tuser.allnames.each { |name|
          @users[name] = tuser
        }
      end
    }
    
    @neednames = true
    
    @blacklist = [
      "twilight",
      "fml",
      "pwn",
      "curer",
      "fullmetal",
      "bleach",
      "gundam",
      "yu yu",
      "naruto",
      "yasha",
      "digimon",
      "bebop",
      "sakura",
      "^\>[a-z]"
    ]
  end

  def getRankList
    sorted = @uniquelist.keys.sort { |a,b|
      #if a happens first, return -1
      #equal 0
      #if b happens first, return 1
      #aval = 0
      #@uniquelist[a].itemList.each { |x|
      #  aval = aval + x
      #}
      
      #bval = 0
      #@uniquelist[b].itemList.each { |x|
      #  bval = bval + x
      #}
      
      #aval = aval*100000 + @uniquelist[a].rankpoints
      #bval = bval*100000 + @uniquelist[b].rankpoints
      aval = @uniquelist[a].rankpoints
      bval = @uniquelist[b].rankpoints
      
      if(aval > bval)
        -1
      elsif(aval == bval)
        0
      else
        1
      end
    }
    
    return sorted
  end

  def save
    File.open(@@DBFILE, 'w') { |f|
      @uniquelist.values.each { |u|
        f.write("#{u.toEntry}\n")
      }
    }
  end

  def queryOtherUser(bot, str)
    #get the speaker
    nick = str[/^:([^!]+)!/, 1]

    chatline = str[/ \:(.+)$/, 1]
    
    #get the user of interest
    if(chatline != nil)
      other = chatline.split(" ")[1]
      if(other != nil && @users[other] != nil)
        rank = 0
        ranklist = getRankList
        ranklist.each_index { |i|
          if(ranklist[i] == @users[other].allnames[0])
            rank = i+1
            break
          end
        }
        
        telluser(bot, nick, "#{@users[other].toString}")
        telluser(bot, nick, "#{other} is ranked #{rank} out of #{ranklist.length}")
      else
        telluser(bot, nick, "User #{other} not found.")
      end
    end
    
  end

  def queryUser(bot, str)
    #get the speaker
    nick = str[/^:([^!]+)!/, 1]
    #puts "nick #{nick}"
    
    #target = str[/PRIVMSG (\S+)/, 1]
    #puts "target: #{target}"
    telluser(bot, nick, "You are: #{@users[nick].toString}")
    
    rank = 0
    ranklist = getRankList
    ranklist.each_index { |i|
      if(ranklist[i] == @users[nick].allnames[0])
        rank = i+1
        break
      end
    }
    
    telluser(bot, nick, "Your rank is: #{rank} out of #{ranklist.length}")
  end
  
  def getSpacestr
   if(@spacestr == "")
     @spacestr = " "
   else
     @spacestr = ""
   end
   
   return @spacestr
  end
  
  def tellchat(bot, target, str)
    if(target != nil)
      if(@users[target] != nil && @users[target].wantspm > 0)
        bot.say(target, "#{str}#{getSpacestr}")
      end
      
      #tell the rest of the users who want to know
      @users.each { |k,v|
        if(v != @users[target] && v.wantspm == 2 && v.isHere)
          bot.say(k, "#{str}#{getSpacestr}")
        end
      }
    end
  end
  
  def telluser(bot, target, str)
    if(target != nil)
      #check for users who want PMs      
      if(@users[target] != nil) #&& @users[target].wantspm > 0)
        bot.say(target, "#{str}#{getSpacestr}")
      end
    end
  end

  def getActives(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    
    online = ""
    offline = ""
    offc = 0
    onc = 0
    @uniquelist.each { |k,v|
      if(v.wantspm > 0)
        str = ""
        if(v.wantspm == 2)
          str << "*"
        end
        str << "#{v.allnames[0]} "
      
        if(v.isHere)
          online << str
          onc = onc + 1
        else
          offline << str
          offc = offc + 1
        end
      end
    }
    
    telluser(bot, nick, "There are currently #{offc+onc} active players.")
    telluser(bot, nick, "Offline [#{offc}]: #{offline}")
    telluser(bot, nick, "Online  [#{onc}]: #{online}")
  end

  def getOpponent(nick)
    ranklist = getRankList
    
    #get all players within n of nick's rank and add some randoms
    rank = 0
    ranklist.each_index { |i|
      if(ranklist[i] == @users[nick].allnames[0])
        rank = i
        break
      end
    }

    upper = rank-5
    if(upper < 0)
      upper = 0
    end
    
    lower = rank+5
    if(lower >= ranklist.length)
      lower = ranklist.length-1
    end
  
    #now we need to add a random not between upper and lower
    ur = -1
    if(upper != 0)
      ur = rand(upper)
    end
   
    lr = rand(ranklist.length-lower)
    lr = lr+lower+1
    
    #which to pick?
    #we are contained between lower and upper, so really we have lower-upper choices
    #plus the ones for ur and lr
    pick = rand(lower-upper-1+2)
    pick = pick+upper
    if(pick >= rank)
      pick = pick+1
    end
    
    if(pick-lower == 1)
      if(ur != -1)
        pick = ur
      else
        pick = lr
      end
    elsif(pick-lower == 2)
      pick = lr
    end
  
    #puts "rank: #{rank} opponent: #{upper} to #{lower}, ur: #{ur}, lr: #{lr}, pick=#{pick}"
    opp = @users[ranklist[pick]]
    
    return opp
  end

  def process(bot, str)
    #arr = str.split(" ", 6)
    #bot.say(arr[4], arr[5]) #target, message 
    
    #puts "STR: #{str}"
    
    #get the speaker
    nick = str[/^:([^!]+)!/, 1]
    #puts "nick #{nick}"
    
    target = str[/PRIVMSG (\S+)/, 1]
    #puts "target: #{target}"
    
    #seems to be a weird issue with my dc++ gateway
    if(target == bot.nick || target == "None")
      return
    end
    
    if(@users[nick] == nil)
      @users[nick] = User.new("#{nick}\t0\t0\t0\t0\t")
      @uniquelist[nick] = @users[nick]
      #if(target != nil)
      #  bot.say(target, "New user created: #{@users[nick].toString}")
      #end
    end
    
    chatline = str[/ \:(.+)$/, 1]
    length = 0
    if(chatline != nil)
      length = chatline.split(" ").length
      
      #Let's look at some penalties
      @blacklist.each { |s|
        if(chatline[/#{s}/i] != nil)
          tellchat(bot, nick, "#{nick} has been penalized for saying a blacklisted word!")
          @users[nick].penalize
          #just penalize once
          break
        end
      }
    end
    
    #length = str.length - str.index(" :") - 4 #accounts for newline and " :"
    #puts "length #{length}"
    
    opp = getOpponent(nick)

    if(chatline[0] != "!"[0])
      #puts "addinng line! #{chatline[0]}"
      @users[nick].addLine(length, opp) #length in words, random opponent in case there's a fight!
    end
    
    #does it contain a url?
    url = str[/(http\:\/\/\S+)/, 1]
    if(url != nil)
      @users[nick].addUrl
    end
    
    if(url != nil)
      #puts "url: #{url}"
      #check if it's an image
      if(url[/\.(jpe?g|png|gif|bmp)$/i])
        #puts "image!"
        @users[nick].addImage
      end
      
      if(url[/youtube.com/])
        #puts "youtube!"
        @users[nick].addYoutube
      end
    end
    
    if(@users[nick].lastNotice != nil)
      tellchat(bot, nick, @users[nick].lastNotice)
    end
    
    save
    
    if(@neednames)
      bot.sendraw("NAMES #{target}")
    end
  end
  
  def enablePM(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    if(@users[nick] != nil)
      @users[nick].enablePM
      telluser(bot, nick, "You will now receive personal PM updates. To get all updates use !allpm. To turn off updates use !nopm. Use !rpg to learn more about yourself.")
    end
    
    save
  end
  
  def enableAllPM(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    if(@users[nick] != nil)
      @users[nick].enableAllPM
      telluser(bot, nick, "You will now receive all PM updates. To get updates only about yourself use !yespm. To disable all updates use !nopm.")
    end
    
    save
  end
  
  def disablePM(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    if(@users[nick] != nil)
      telluser(bot, nick, "All future PMs are disabled. Use !yespm to undo this.")
      @users[nick].disablePM
    end
    
    save
  end
  
  def help(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    if(@users[nick] != nil)
      telluser(bot, nick, "Commands:")
      telluser(bot, nick, "!rpg       - learn about yourself")
      telluser(bot, nick, "!rpgu user - learn about user")
      telluser(bot, nick, "!allpm     - enable PM updates about all players")
      telluser(bot, nick, "!yespm     - enable personal PM updates only")
      telluser(bot, nick, "!nopm      - disable all PM updates")
      telluser(bot, nick, "!top10     - see the top 10 users")
    end
  end
  
  def ishere(bot, str)
    nick = str[/^:([^!]+)!/, 1]

    chatline = str[/ \:(.+)$/, 1]
        
    #get the user of interest
    if(chatline != nil)
      other = chatline.split(" ")[1]
      if(@users[other])
        telluser(bot, nick, "#{other} is marked #{@users[other].isHere ? "here" : "gone"}")
      else
        telluser(bot, nick, "#{other} not found")
      end
    end
  end
  
  def top10(bot, str)
    @exclude = [
      "cookiebot",
      "nehsA",
      "bottiger"
    ]
    
    nick = str[/^:([^!]+)!/, 1]
    if(@users[nick] != nil)
      cc = 1
      getRankList.each { |t|
        skip = false
        @exclude.each { |e|
          if(e == t)
            skip = true
          end
        }
        
        if(!skip)
          telluser(bot, nick, "#{cc}. #{@uniquelist[t].toString}")
          cc = cc+1
          if(cc > 10)
            break
          end
        end
      }
    end
  end
  
  def joins(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    #puts "JOINS: [#{nick}]"
    if(@users[nick])
      @users[nick].markHere
    end
  end

  def parts(bot, str)
    nick = str[/^:([^!]+)!/, 1]
    #puts "PARTS: [#{nick}]"
    if(@users[nick])
      @users[nick].markGone
    end
  end
  
  def names(bot, str)
    arr = str.split(" ", 6)
    #arr[5] is the names, but the first one starts with a colon, also make sure to strip @s
    names = arr[5].split(" ")
    names[0] = (names[0])[1,names[0].length-1]
    
    names.each { |n|
      if(n[0] == "@"[0].to_i)
         n = (n)[1,n.length-1]
      end
      
      if(@users[n])
        @users[n].markHere
      end
    }
    
    @neednames = false
  end
  
end

m = HubRPG.new
CommandManager.add("", m.method(:process))
CommandManager.add("!rpg", m.method(:queryUser))
CommandManager.add("!rpgu", m.method(:queryOtherUser))
CommandManager.add("!yespm", m.method(:enablePM))
CommandManager.add("!nopm", m.method(:disablePM))
CommandManager.add("!allpm", m.method(:enableAllPM))
CommandManager.add("!top10", m.method(:top10))
CommandManager.add("!actives", m.method(:getActives))
CommandManager.add("!ishere", m.method(:ishere))
CommandManager.add("!help", m.method(:help))
CommandManager.add("/rpg", m.method(:queryUser))
CommandManager.add("/rpgu", m.method(:queryOtherUser))
CommandManager.add("/yespm", m.method(:enablePM))
CommandManager.add("/nopm", m.method(:disablePM))
CommandManager.add("/allpm", m.method(:enableAllPM))
CommandManager.add("/top10", m.method(:top10))
CommandManager.add("/help", m.method(:help))

CommandManager.addProt("JOIN", m.method(:joins))
CommandManager.addProt("PART", m.method(:parts))
CommandManager.addProt("353", m.method(:names))
