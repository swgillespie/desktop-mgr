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

require 'thor'
require 'terminal-table'
require 'desktop'

trap("SIGINT") { exit! }

DESKTOP_FILE_NAME = 'Desktopfile'
DESKTOP_FILE = <<-FILE
configuration :default do
  env 'IN_BASIC', '1'
end
FILE

module Desktop
  class CLI < Thor
    include Thor::Actions

    map %w(-v --version) => :version

    desc 'version', 'Display the version of Desktop'
    def version
      puts Desktop::VERSION
    end

    desc 'list', 'Lists all workspaces'
    def list
      workspaces = Workspace.all
      if workspaces.empty?
        puts "No workspaces found. Create a few with `desktop new`!"
        return
      end

      headings = ['Name', 'Description', 'Path']
      rows = []
      Workspace.all.each do |w|
        rows << [w.name, w.description, w.path]
      end

      table = Terminal::Table.new :headings => headings, :rows => rows
      puts "All active workspaces: "
      puts
      puts table
    end

    desc 'new <name> <description>', 'Creates a new workspace'
    def new(name, description)
      path = Dir.getwd
      puts "Creating a new workspace in directory #{path}..."

      # bail if there already exists a workspace by that name
      existing = Workspace.first(:name => name)
      if existing
        puts "A workspace with name #{name} already exists!"
        puts "Workspace \"#{name}\" can be found at #{existing.path}"
        return
      end
      Workspace.insert :name => name, 
        :description => description, 
        :path => path,
        :created_at => Time.now,
        :modified_at => Time.now,
        :last_used_at => Time.now
      puts "Creating an empty Desktopfile in this directory..."
      File.write DESKTOP_FILE_NAME, DESKTOP_FILE
      puts "Done!"
    end

    desc 'go <workspace> <configuration>', 'Goes to and activates a workspace'
    def go(workspace, configuration)
      wks = Workspace.first(:name => workspace)
      unless wks
        puts "Failed to find a workspace with the name \"#{workspace}\"!"
        return
      end
      
      # move to this directory
      Dir.chdir wks.path

      # read and eval the Desktopfile in this directory, if it exists
      file = File.join wks.path, DESKTOP_FILE_NAME
      unless File.exist? file
        puts "Failed to find a Desktopfile! Expected one to be here: #{file}"
        return
      end

      env = Environment.define file
      config = env.configurations[configuration.to_sym]
      unless config
        puts "Failed to find a configuration named \"#{configuration}\" in the Desktopfile!"
        return
      end

      # now that we have a config, it's time to set up and spawn our subshell.
      # since aliases are per-shell, we need to generate a temporary shell file
      # that we'll eval before we give control back to the user.
      shell = Tempfile.new('desktop')

      # TODO(segilles) detect the bash init script
      shell.puts "source ~/.bash_profile"
      shell.puts "export PS1=\"(#{wks.name}/#{configuration}) $PS1\""
      config.environment_variables.each do |k, v|
        shell.puts "export #{k}=#{v}"
      end

      config.aliases.each do |k, v|
        shell.puts "alias #{k}=\"#{v}\""
      end

      shell.close

      # let's go!'
      puts "Activating configuration #{configuration} in workspace #{wks.name}"
      Kernel.exec "bash --init-file #{shell.path}"
    end
  end
end
