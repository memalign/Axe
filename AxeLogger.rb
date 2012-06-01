#!/usr/bin/ruby
#

require 'singleton'

class AxeLogger
    attr_writer :shouldLog

    @@instance = self.new

    def initialize
        @shouldLog = false
    end

    def self.setShouldLog(shouldLog)
        @@instance.shouldLog = shouldLog
    end

    def self.puts(str)
        @@instance.puts(str)
    end

    def puts(str)
        if (@shouldLog)
            Kernel.puts str
        end
    end
end
