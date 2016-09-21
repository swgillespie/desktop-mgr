# Copyright (c) 2016 Sean Gillespie
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# afurnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'logger'

module Desktop
  require 'desktop/version'
  require 'desktop/db'
  require 'desktop/model'
  require 'desktop/env'
  # This is your gem's load point. Require your components here.

  class << self
    ##
    # Retrieves the logger for this process. Will be an object that responds
    # to +debug+, +info+, +warn+, and +error+.
    def log
      unless @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
        @logger.formatter = proc do |severity, timestamp, progname, msg|
          "#{severity}: #{msg}\n"
        end
      end

      @logger
    end
  end
end
