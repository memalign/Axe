#!/usr/bin/ruby

#@@cmd = { }
class CommandManager
  
  @@cmd = { }
  @@giveall = Array.new
  @@prothooks = { }

  def CommandManager.clear()
    @@cmd = { }
    @@giveall = Array.new
    @@prothooks = { }
  end
  
  def CommandManager.addProt(num, cmdref)
    @@prothooks[num] = cmdref
  end
  
  def CommandManager.add(hook, cmdref)
    if(hook == "")
      @@giveall << cmdref
    else
      @@cmd[hook] = cmdref
    end
  end
  
  def CommandManager.del(hook)
    if(hook != "")
      @@cmd[hook] = nil
    end
  end
  
  def CommandManager.execCmd(bot, hook, str)
    #puts "execCmd [ #{hook} ]"
    @@giveall.each { |cmd|
      cmd.call(bot, str)
    }

    if(@@cmd[hook])
      @@cmd[hook].call(bot, str)
    end
  end

  def CommandManager.protocolHooks(bot, num, str)
    if(@@prothooks[num])
      @@prothooks[num].call(bot, str)
    end
  end
  
end
