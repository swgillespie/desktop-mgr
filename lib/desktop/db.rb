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
require 'sequel'

DESKTOP_DIR = File.join Dir.home, '.desktop'
DB_FILE = File.join DESKTOP_DIR, 'desktop.db'
CURRENT_WORKSPACE_FILE = 'current_workspace.txt'

module Desktop
  ## 
  # This class reads and writes data in the V1 database schema,
  # which is the first stable schema format for Desktop database stores.
  class DatabaseV1
    ##
    # Creates the Sequel DB instance corresponding to the first version
    # of the Desktop schema.
    def self.create_db
      db = Sequel.sqlite DB_FILE
      db.create_table? :workspaces do
        primary_key :id
        String :name
        String :description, :text => true
        String :path,        :text => true
        DateTime :created_at
        DateTime :modified_at
        DateTime :last_used_at
      end

      db.create_table? :tags do
        primary_key :id
        String :name
      end

      db.create_table? :workspace_tags do
        primary_key :id
        foreign_key :tag_id, :tags
        foreign_key :workspace_id, :workspaces
      end

      return db
    end
  end

  DB = DatabaseV1.create_db
end
