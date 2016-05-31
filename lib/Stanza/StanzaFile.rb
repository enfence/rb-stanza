#!/usr/bin/ruby
# StanzaFile Class
# This file is a part of rb-stanza library
#
# Author::    Andrey Klyachkin <andrey.klyachkin@enfence.com>
# Copyright:: Copyright (c) 2016 eNFence GmbH
# License::   Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'erb'
require 'tempfile'

module Stanza
  # Class StanzaFile represents the file with one or many stanzas,
  # e.g. _/etc/filesystems_, _/etc/security/login.cfg_ or some other.
  # The file usually begins with comments, describing the file itself
  # and possible stanzas in it. After that goes different stanzas.
  # Each of them can have its own comment with description of
  # possible attributes and their values.
  #
  # For description of stanzas see doc. to class Stanza
  #
  # All changes made to the object are not written to the disk
  # until the call of +write!+ function
  class StanzaFile
    # creates a new object. If file +file+ exists, it
    # reads its contents. If the file doesn't exist, it
    # will be created.
    #
    #  f = Stanza::StanzaFile.new('/etc/filesystems')
    def initialize(file)
      @file_name = file
      @comment_char = '*'
      @comment = ''
      @stanzas = []
      if ::File.exist?(file)
        readStanzaFile(file)
      else
        ::File.new(file, File::CREAT | File::WRONLY, 0644)
      end
    end

    # empties the contents of the object and re-reads
    # it from the file again.
    #
    #  f = Stanza::StanzaFile.new('/etc/filesystems')
    #  # we did here something nasty with +f+ and want to revert it back
    #  f.read!
    def read!
      empty!
      read_stanza_file(@fileName)
    end

    # writes the contents of the object into file.
    #
    #  f = Stanza::StanzaFile.new('/etc/filesystems')    # read /etc/filesystems
    #  f.set_stanza_attr('/home', 'log', 'INLINE')
    #                                 # set attribute log=INLINE in stanza /home
    #  f.write!
    #                                # write everything back to /etc/filesystems
    def write!
      write_stanza_file(@fileName)
    end

    # clears the contents of the object
    def empty!
      @comment = ''
      @stanzas = []
    end

    # reads the contents of the file and replaces the current object with it
    #
    #  f = Stanza::StanzaFile.new('/etc/filesystems')    # read /etc/filesystems
    #  f.read_from_file('/tpl/filesystems.template')
    #                         # read stanzas from file /tpl/filesystems.template
    #  f.write!
    #                                             # write it to /etc/filesystems
    def read_from_file(file)
      empty!
      read_stanza_file(file)
    end

    # writes the contents of the object to some other file
    #
    #  f = Stanza::StanzaFile.new('/etc/filesystems')    # read /etc/filesystems
    #  f.write_to_file('/etc/filesystems.bak')
    #                                    # make a backup copy before changing it
    def write_to_file(filename)
      write_stanza_file(filename)
    end

    # adds a comment line to the file
    def add_comment(comment)
      @comment += comment + "\n"
    end

    # adds a new stanza to the file
    def add_stanza(stanza)
      @stanzas << stanza if stanza.is_a?(Stanza)
    end

    # replaces the stanza +name+ in the file with another stanza
    def set_stanza(name, stanza)
      if stanza.is_a?(Stanza)
        @stanzas.each do |st|
          st.copy(stanza) if st.name == name
        end
      end
    end

    # removes the stanza +name+ from the file
    def delete_stanza(name)
      @stanzas.each do |st|
        @stanzas.delete(st) if st.name == name
      end
    end

    # returns Stanza object of the stanza +name+
    def get_stanza(name)
      @stanzas.each do |st|
        return st if st.name == name
      end
      nil
    end

    # sets the attribute +attr+ in the stanza +stanza_name+ to value +value+
    def set_stanza_attr(stanza_name, attr, value)
      @stanzas.each do |st|
        st.set_attribute(attr, value) if st.name == stanza_name
      end
    end

    # returns value of the attribute +attr+ in the stanza +stanza_name+
    def get_stanza_attr(stanza_name, attr)
      @stanzas.each do |st|
        return st.get_attribute(attr) if st.name == stanza_name
      end
    end

    # removes the attribute +attr+ from the stanza +stanza_name+
    def delete_stanza_attr(stanza_name, attr)
      @stanzas.each do |st|
        st.del_attribute(attr) if st.name == stanza_name
      end
    end

    # returns the textual representation of the stanza file
    def to_s
      @stanzas.each do |st|
        st.comment_char = @comment_char
      end
      s = ERB.new("<% @comment.lines do |line| %>
<%= @comment_char %> <%= line %>
<% end %>

<% @stanzas.each do |st| %>
<%= st %>

<% end %>
", 0, '<>').result(binding)
      s
    end

    private

    def write_stanza_file(file)
      open(file, 'w') do |f|
        f.write(to_s)
      end
    end

    def read_stanza_file(file)
      open(file) do |f|
        stanza_name = ''
        stanza_lines = []
        nextcomment = ''
        f.each do |line|
          next if line.nil?
          line.rstrip!
          if line.start_with?(@comment_char)
            if stanza_name == '-'
              nextcomment += line.sub(/^./, '').strip + "\n"
            else
              @comment += line.sub(/^./, '').strip + "\n"
            end
            next
          end
          if line.end_with?(':')
            stanza_name = line.gsub(/:$/, '')
            next
          end
          if line.empty?
            unless stanza_name == '' || stanza_name == '-'
              s = read_stanza(stanza_name, stanza_lines)
              s.comment = nextcomment unless s.nil?
              @stanzas << s unless s.nil?
              stanza_name = '-'
              stanza_lines = []
              nextcomment = ''
            end
            next
          end
          stanza_lines << line unless stanza_name == '' || stanza_name == '-'
        end
      end
    end

    def read_stanza(name, lines)
      return nil if name == '' || name == '-'
      h = {}
      lines.each do |line|
        line.strip!
        s_attr, s_value = line.split('=')
        next if s_attr.nil?
        next if s_value.nil?
        s_attr.strip!
        s_value.strip!
        h[s_attr] = s_value
      end
      s = Stanza.new(name, h)
      s
    end

    # character which denotes comments in the file
    attr_accessor :comment_char
    # array of Stanza objects, representing all the stanzas in the file
    attr_accessor :stanzas
    alias clear! empty!
    alias inspect to_s
  end
end
