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

require 'terminal-table'
require 'time_ago_in_words'

module Desktop
  ##
  # A collection of utility functions.
  module Utility
    ##
    # Renders a list of workspaces into a printable object.
    def self.draw_workspaces(workspace_list)
      headings = ['Name', 'Description', 'Path', 'Last Used']
      rows = []
      workspace_list.each do |w|
        last_used_at = w.last_used_at.ago_in_words
        rows << [w.name, w.description, w.path, last_used_at]
      end

      return Terminal::Table.new :headings => headings, :rows => rows
    end

    ##
    # Renders a list of tags into a printable object.
    def self.draw_tags(tag_list)
      headings = ['Tag', 'Usage Count']
      rows = []
      tag_list.each do |t| 
        count = WorkspaceTag.where(:tag_id => t.id).count
        rows << [t.name, count]
      end

      table = Terminal::Table.new :headings => headings, :rows => rows
      table.align_column 1, :right
      return table
    end
  end
end