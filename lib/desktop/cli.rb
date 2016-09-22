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
require 'desktop'

trap("SIGINT") { exit! }

DESKTOP_FILE_NAME = 'Desktopfile'
DESKTOP_FILE = <<-FILE
configuration :default do
  env 'IN_BASIC', '1'
end
FILE

module Desktop
  class Tags < Thor
    desc "add <workspace> <tag>", "Adds a tag to a given workspace."
    def add(workspace, tag)
      wks = Workspace.first(:name => workspace)
      unless wks
        puts "No workspace found with the name \"#{workspace}\"!"
        return
      end

      tag_obj = Tag.first(:name => tag)
      unless tag_obj
        puts "No tag found with the name \"#{tag}\"!"
        return
      end

      WorkspaceTag.insert :tag_id => tag_obj.id, :workspace_id => wks.id
    end

    desc "show [--tag=TAG] [--workspace=WORKSPACE]", "Shows all workspaces associated with a tag, or all tags associated with a workspace."
    method_option :tag, :type => :string, :aliases => '-t', :desc => "Given this tag, prints out all workspaces that use this tag"
    method_option :workspace, :type => :string, :aliases => '-w', :desc => "Given this workspace, prints out all tags attached to it"
    def show
      if options["tag"] and options["workspace"]
        puts "The tag and workspace options are mutually exclusive!"
        return
      end

      if options["tag"].nil? and options["workspace"].nil?
        puts "Either one of the tag or workspace options must be provided!"
        return
      end

      if options["tag"]
        tag = Tag.where(:name => options["tag"]).first
        unless tag
          puts "No tag found with the name \"#{options["tag"]}\""
          return
        end

        spaces = Workspace.join(:workspace_tags, :workspace_id => :id)
          .where(:tag_id => tag.id)
          .order(Sequel.desc(:last_used_at))
          .all

        if spaces.empty?
          puts "No workspaces found with the given tag"
          return
        end

        table = Utility::draw_workspaces spaces
        puts "All workspaces with the tag \"#{tag.name}\": "
        puts
        puts table
        return
      end

      workspace = Workspace.where(:name => options["workspace"]).first
      unless workspace
        puts "No workspace found with the name \"#{options["workspace"]}\""
        return
      end

      tags = Tag.join(:workspace_tags, :tag_id => :id)
        .where(:workspace_id => workspace.id)
        .all

      if tags.empty?
        puts "No tags found on the given workspace"
        return
      end

      table = Utility::draw_tags tags
      puts "All tags on workspace #{workspace.name}: "
      puts
      puts table
    end

    desc "new <tag>", "Creates a new tag with the given name"
    def new(name)
      existing = Tag.first :name => name
      if existing
        puts "A tag by that name already exists!"
        return
      end

      Tag.insert :name => name
      puts "Done!"
    end

    desc "list", "List all tags known to Desktop"
    def list
      tags = Tag.all
      if tags.empty?
        puts "No tags found! Create a few with `desktop tags new`!"
        return
      end

      table = Utility::draw_tags tags
      puts "All active tags: "
      puts
      puts table
    end
  end

  class CLI < Thor
    include Thor::Actions

    desc "tags SUBCOMMAND", "Manipulates tags on workspaces."
    subcommand "tags", Tags

    map %w(-v --version) => :version

    desc 'version', 'Display the version of Desktop.'
    def version
      puts Desktop::VERSION
    end

    desc 'list', 'Lists all workspaces.'
    def list
      workspaces = Workspace.order(Sequel.desc(:last_used_at)).all
      if workspaces.empty?
        puts "No workspaces found. Create a few with `desktop new`!"
        return
      end

      table = Utility::draw_workspaces workspaces
      puts "All active workspaces: "
      puts
      puts table
    end

    desc 'new <name> <description>', 'Creates a new workspace.'
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

      # only generate the Desktopfile if there's not one there already
      unless File.exist? DESKTOP_FILE_NAME
        puts "Creating an empty Desktopfile in this directory..."
        File.write DESKTOP_FILE_NAME, DESKTOP_FILE
      end
      puts "Done!"
    end

    desc 'go <workspace> [<configuration>]', 'Goes to and activates a workspace. If no configuration is given, defaults to \'default\'.'
    def go(workspace, configuration = 'default')
      wks = Workspace.first(:name => workspace)
      unless wks
        puts "Failed to find a workspace with the name \"#{workspace}\"!"
        return
      end
      
      # move to this directory
      Dir.chdir wks.path

      # read and eval the Desktopfile in this directory, if it exists.
      file = File.join wks.path, DESKTOP_FILE_NAME
      if File.exist? file
        # this evals the file.
        env = Environment.define file
        config = env.configurations[configuration.to_sym]
        unless config
          puts "Failed to find a configuration named \"#{configuration}\" in the Desktopfile!"
          return
        end
      else
        # no Desktopfile -> empty config.
        config = Configuration.new
      end

      # now that we have a config, it's time to set up and spawn our subshell.
      # since aliases are per-shell, we need to generate a temporary shell file
      # that we'll eval before we give control back to the user.
      shell = Tempfile.new('desktop')

      # see https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html
      # for the files that Bash normally reads on startup, that we'll reproduce here
      # (since we're providing our own init file)
      shell.puts "if [ -f /etc/profile ]; then source /etc/profile; fi"
      shell.puts "if [ -f ~/.bash_profile ]; then source ~/.bash_profile; fi"
      shell.puts "if [ -f ~/.bash_login ]; then source ~/.bash_login; fi"
      shell.puts "if [ -f ~/.profile ]; then source ~/.profile; fi"
      shell.puts "if [ -f ~/.bashrc ]; then source ~/.bashrc; fi"

      shell.puts "export PS1=\"(\e[31m#{wks.name}\e[m/\e[34m#{configuration}\e[m) $PS1\""
      config.environment_variables.each do |k, v|
        shell.puts "export #{k}=#{v}"
      end

      config.aliases.each do |k, v|
        shell.puts "alias #{k}=\"#{v}\""
      end

      config.commands.each do |cmd|
        shell.puts cmd
      end

      shell.close

      # update the last used time on the workspace
      wks.update(:last_used_at => Time.now)

      # let's go!
      puts "Activating configuration #{configuration} in workspace #{wks.name}"
      Kernel.exec "bash --init-file #{shell.path}"
    end
  end
end
