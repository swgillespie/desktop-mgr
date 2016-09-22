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

require 'os'

module Desktop
  ##
  # An environment is a collectino of user-provided environmental 
  # configurations that are evaluated when a user switches to a 
  # workspace. It contains environment variables, aliases, etc. 
  # that a user might want to keep local to a workspace.
  #
  # Environments are defined using a DSL by the user, as defined here.
  class Environment
    attr_reader :configurations

    ##
    # Initializes this environment to be an empty list of configurations.
    def initialize
      @configurations = {}
    end

    ##
    # Defines a configuration by loading the DSL file and executing it.
    def self.define(filename)
      dsl = Environment.new
      dsl.instance_eval(File.read filename)
      return dsl
    end

    ##
    # Defines a new configuration with the given name.
    def configuration(name, &block)
      config = Configuration.new
      config.instance_eval(&block)
      @configurations[name] = config
    end
  end

  ##
  # A Configuration is a collection of environment variables
  # and command aliases that will be applied upon entry to the
  # environment.
  class Configuration
    attr_reader :environment_variables
    attr_reader :aliases
    attr_reader :commands

    ##
    # Initializes the configuration to have no env vars and
    # no aliases.
    def initialize
      @environment_variables = {}
      @aliases = {}
      @commands = []
    end

    ##
    # Defines a new environment variable.
    def env(key, value)
      @environment_variables[key] = value 
    end

    ##
    # Defines a new command alias.
    def alias_cmd(key, value)
      @aliases[key] = value
    end

    ##
    # Schedules a string to be echoed.
    def echo(string)
      @commands << "echo #{string}"
    end

    ##
    # Schedules a command to be run.
    def cmd(string)
      @commands << string
    end

    ##
    # Evals a block only if the current operating
    # system matches the named operating system.
    # names can be one of :linux, :macos, or :windows
    def os(*names, &block)
      if OS.linux? and names.include? :linux
        instance_eval &block
      elsif OS.mac? and names.include? :macos
        instance_eval &block
      elsif OS.windows? and names.include? :windows
        instance_eval &block
      end
    end
  end
end