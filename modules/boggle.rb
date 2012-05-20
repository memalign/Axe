#!/usr/bin/ruby
require 'set'
#require "CommandManager"

class Boggle
  def initialize()
    @suffix = ""
    @scores = Hash.new
    @uniqueNames = []
    File.open("modules/boggle.txt", 'r') { |f| 
      f.readlines.each { |l|
          #format is User\tnumwins\tnumgames\tpoints
          arr = l.split("\t")
          names = arr[0].upcase.split("!")
          @uniqueNames << arr[0].upcase
          @scores[names[0]] = [arr[1].to_i,arr[2].to_i,arr[3].to_i]
          names.each { |n|
            @scores[n] = @scores[names[0]]
          }
      }
    }
    @gameThread = nil
    @startMutex = Mutex.new
    @gameMutex = Mutex.new
    @mode = nil
  end

  def writeScores
    File.open("modules/boggle.txt", 'w') { |f|
        @uniqueNames.each { |s|
            u = s.split("!")[0]
            f.write("#{s}\t#{@scores[u][0]}\t#{@scores[u][1]}\t#{@scores[u][2]}\t#{@scores[u][3]}\n")
        }
    }
  end

  def startBoggle(bot, str)
      nick = str[/^:([^!]+)!/, 1]
      channel = str[/PRIVMSG (\#\S+)/, 1]
      #if(bot.owner == nick)
          #make sure a game isn't already in progress
          @startMutex.synchronize {
              if(@gameThread.nil?)
                @gameThread = Thread.new {
                    playGame(bot, channel)
                }
              else
                  say(bot, channel, "Game already in progress! Try again later.")
              end
          }
          #create a new game
      #end
  end

  def playGame(bot, chan)
      #gamelogic

      say(bot, chan, "Starting boggle! Use \"!play\" to join in the next 30 seconds.")
      @gameMutex.synchronize {
        @mode = "join"
        @players = Hash.new
        @allwords = Set.new
      }
      sleep(30)

      @gameMutex.synchronize {
          @mode = nil
      }

      if(@players.length < 2)
          say(bot, chan, "Uh oh, too few players, aborting!")
      else 
          say(bot, chan, "Generating game board...")
          #pick a face for each cube
          dice = []
          dice << ["T", "O", "E", "S", "S", "I"]
          dice << ["A", "S", "P", "F", "F", "K"]
          dice << ["N", "U", "I", "H", "M", "Qu"]
          dice << ["O", "B", "J", "O", "A", "B"]
          dice << ["L", "N", "H", "N", "R", "Z"]
          dice << ["A", "H", "S", "P", "C", "O"]
          dice << ["R", "Y", "V", "D", "E", "L"]
          dice << ["I", "O", "T", "M", "U", "C"]
          dice << ["L", "R", "E", "I", "X", "D"]
          dice << ["T", "E", "R", "W", "H", "V"]
          dice << ["T", "S", "T", "I", "Y", "D"]
          dice << ["W", "N", "G", "E", "E", "H"]
          dice << ["E", "R", "T", "T", "Y", "L"]
          dice << ["O", "W", "T", "O", "A", "T"]
          dice << ["A", "E", "A", "N", "E", "G"]
          dice << ["E", "I", "U", "N", "E", "S"]

          @chosen = []
          dice.each { |d|
            @chosen << d[rand(d.length)]
          }

          (0..(@chosen.length-1)).each { |i|
              temp = @chosen[i]
              j = rand(@chosen.length)
              @chosen[i] = @chosen[j]
              @chosen[j] = temp
          }

          printBoard(bot, chan, @chosen)
          @gameMutex.synchronize {
              @mode = "find"
          }
          say(bot, chan, "There are 2 minutes remaining! Find as many words as possible.")

          sleep(30)
          say(bot, chan, "There are 1.5 minutes remaining!")
          printBoard(bot, chan, @chosen)

          sleep(30)
          say(bot, chan, "There is 1 minute remaining!")
          printBoard(bot, chan, @chosen)

          sleep(30)
          say(bot, chan, "There are 30 seconds remaining!")
          printBoard(bot, chan, @chosen)

          sleep(30)
          say(bot, chan, "Time's up! Let's see those scores:")

          @gameMutex.synchronize {
              @mode = nil
          }
          bestScore = -1
          bestPlayer = ""
          winners = []
          @players.keys.each { |p|
            wordStr = ""
            score = 0
            @players[p].sort.each { |s|
                wordStr << "#{s} "
                case s.length
                    when 1
                        score += 0
                    when 2
                        score += 0
                    when 3
                        score += 1
                    when 4
                        score += 1
                    when 5
                        score += 2
                    when 6
                        score += 3
                    when 7
                        score += 5
                    else
                        score += 11
                end
            }
            say(bot, chan, "#{p}, score #{score}: #{wordStr}")
            #@scores[p.upcase][0] #wins
            if(@scores[p.upcase].nil?)
                @scores[p.upcase] = [0,0,0]
            end
            @scores[p.upcase][1] += 1 #games
            @scores[p.upcase][2] += score #points

            if(score > bestScore)
                bestScore = score
                bestPlayer = p
                winners = [p]
            elsif(score == bestScore)
                bestPlayer = "#{bestPlayer}, #{p}"
                winners << p
            end
          }
          say(bot, chan, "#{bestPlayer} win#{bestPlayer.index(",").nil? ? "s" : ""} with a score of #{bestScore}!!")
          winners.each { |w|
            @scores[w.upcase][0] += 1
          }
          writeScores
      end

      @startMutex.synchronize {
          @gameThread = nil
      }
  end

  def printBoard(bot, chan, board)
      str = ""
      (0..15).each { |i|
          str << board[i].ljust(3)
          if(i%4 == 15%4)
            say(bot, chan, str)
            str = ""
          end
      }
  end

  def joinBoggle(bot, str)
      @gameMutex.synchronize {
        if(@mode == "join")
          nick = str[/^:([^!]+)!/, 1]
          channel = str[/PRIVMSG (\#\S+)/, 1]
          if(@players[nick].nil?)
              @players[nick] = Set.new
              say(bot, channel, "#{nick} has joined boggle.")
          end
        end
      }
  end

  def validBoggleWord(word)
    #@chosen is the gameboard
    board = [[], [], [], []]
    (0..15).each { |i|
        board[i/4][i%4] = @chosen[i].downcase
    }

    (0..3).each { |i|
        (0..3).each { |j|
            if(board[i][j][0].chr == word[0].chr)
                if(findPath(i, j, board, word))
                    return true
                end
            end
        }
    }

    return false
  end


  def findPath(i, j, board, word)
    if(i < 0 || j < 0 || i >= 4 || j >= 4)
        return false
    end

    if(word.length == 0)
        return true
    end

    ret = false
    if(word[0].chr == board[i][j][0].chr)
        board[i][j].upcase!
        nextWord = word[1..-1]
        if(word[0].chr == "q")
            nextWord = word[2..-1]
        end
        ret = findPath(i-1, j-1, board, nextWord) ||
              findPath(i-1, j, board, nextWord) ||
              findPath(i-1, j+1, board, nextWord) ||
              findPath(i, j-1, board, nextWord) ||
              findPath(i, j+1, board, nextWord) ||
              findPath(i+1, j-1, board, nextWord) ||
              findPath(i+1, j, board, nextWord) ||
              findPath(i+1, j+1, board, nextWord)
        board[i][j].downcase!
    end

    return ret
  end

  def boggStat(bot, str)
      nick = str[/^:([^!]+)!/, 1]
      channel = str[/PRIVMSG (\#\S+)/, 1]

      word = str[/PRIVMSG \#\S+ \:\S+ (\S+)/, 1]

      if(!word.nil?)
          nick = word
      end
      arr = @scores[nick.upcase]

      if(arr.nil?)
          say(bot, channel, "#{nick} has not played boggle.")
      else
          say(bot, channel, "#{nick} has won #{arr[0]} out of #{arr[1]} games with a total of #{arr[2]} points")
      end
  end

  def findWords(bot, str)
    @gameMutex.synchronize {
        if(@mode == "find")
          #take a look at the first token
          nick = str[/^:([^!]+)!/, 1]
          channel = str[/PRIVMSG (\#\S+)/, 1]
          if(@players.include?(nick))
            word = str[/PRIVMSG \#\S+ \:(\w+)/, 1]
            if(!word.nil? && word.length > 2)
                word.downcase!
                good = (`echo #{word} | ispell -l` == "")
                if(good)
                   #is it in the square?
                   if(validBoggleWord(word) && !@allwords.include?(word))
                       @players[nick] << word 
                       @allwords << word
                   end
                end
            end
          end
        end
    }
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

m = Boggle.new
CommandManager.add("", m.method(:findWords))
CommandManager.add("!startboggle", m.method(:startBoggle))
CommandManager.add("!boggle", m.method(:startBoggle))
CommandManager.add("!join", m.method(:joinBoggle))
CommandManager.add("!play", m.method(:joinBoggle))
CommandManager.add("!boggstat", m.method(:boggStat))
#CommandManager.addProt("JOIN", m.method(:joins))
#CommandManager.addProt("PART", m.method(:parts))
#CommandManager.addProt("353", m.method(:names))
