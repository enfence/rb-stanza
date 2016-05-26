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
            @fileName = file
            @commentChar = '*'
            @comment = ''
            @stanzas = []
            if ::File.exist?(file)
                readStanzaFile(file)
            else
                ::File.new(file, File::CREAT|File::WRONLY, 0644)
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
            readStanzaFile(@fileName)
        end
    
        # writes the contents of the object into file.
        #
        #  f = Stanza::StanzaFile.new('/etc/filesystems')   # read /etc/filesystems
        #  f.setStanzaAttr('/home', 'log', 'INLINE')        # set attribute log=INLINE in stanza /home
        #  f.write!                                         # write everything back to /etc/filesystems
        def write!
            writeStanzaFile(@fileName)
        end
    
        # clears the contents of the object
        def empty!
            @comment = ''
            @stanzas = []
        end
    
        # reads the contents of the file and replaces the current object with it
        #
        #  f = Stanza::StanzaFile.new('/etc/filesystems')    # read /etc/filesystems
        #  f.readFromFile('/tpl/filesystems.template')       # read stanzas from file /tpl/filesystems.template
        #  f.write!                                          # write it to /etc/filesystems
        def readFromFile(file)
            empty!
            readStanzaFile(file)
        end
    
        # writes the contents of the object to some other file
        #
        #  f = Stanza::StanzaFile.new('/etc/filesystems')   # read /etc/filesystems
        #  f.writeToFile('/etc/filesystems.bak')            # make a backup copy before changing it
        def writeToFile(filename)
            writeStanzaFile(filename)
        end
    
        # adds a comment line to the file
        def addComment(comment)
            @comment += comment + "\n"
        end
    
        # adds a new stanza to the file
        def addStanza(stanza)
            if stanza.kind_of?(Stanza)
                @stanzas << stanza
            end
        end
    
        # replaces the stanza +name+ in the file with another stanza
        def setStanza(name, stanza)
            if stanza.kind_of?(Stanza)
                @stanzas.each do |st|
                    st.copy(stanza) if st.name == name
                end
            end
        end
    
        # removes the stanza +name+ from the file
        def deleteStanza(name)
            @stanzas.each do |st|
                @stanzas.delete(st) if st.name == name
            end
        end
    
        # returns Stanza object of the stanza +name+
        def getStanza(name)
            @stanzas.each do |st|
                return st if st.name == name
            end
            return nil
        end
    
        # sets the attribute +attr+ in the stanza +stanzaName+ to value +value+
        def setStanzaAttr(stanzaName, attr, value)
            @stanzas.each do |st|
                if st.name == stanzaName
                    st.setAttribute(attr, value)
                end
            end
        end
    
        # returns value of the attribute +attr+ in the stanza +stanzaName+
        def getStanzaAttr(stanzaName, attr)
            @stanzas.each do |st|
                if st.name == stanzaName
                    return st.getAttribute(attr)
                end
            end
        end
    
        # removes the attribute +attr+ from the stanza +stanzaName+
        def deleteStanzaAttr(stanzaName, attr)
            @stanzas.each do |st|
                if st.name == stanzaName
                    st.delAttribute(attr)
                end
            end
        end
    
        # returns the textual representation of the stanza file
        def to_s
            @stanzas.each do |st|
                st.commentChar = @commentChar
            end
            s = ERB.new("<% @comment.lines do |line| %>
<%= @commentChar %> <%= line %>
<% end %>

<% @stanzas.each do |st| %>
<%= st %>

<% end %>
", 0, '<>').result(binding)
            return s
        end
    
        private
        def writeStanzaFile(file)
            open(file, 'w') do |f|
                f.write(to_s)
            end
        end
    
        def readStanzaFile(file)
            open(file) do |f|
                stanzaName = ''
                stanzaLines = []
                nextcomment = ''
                f.each do |line|
                    next if line.nil?
                    line.rstrip!
                    if line.start_with?("#{@commentChar}")
                        if stanzaName == '-'
                            nextcomment += line.sub(/^./, "").strip + "\n"
                        else
                            @comment += line.sub(/^./, "").strip + "\n"
                        end
                        next
                    end
                    if line.end_with?(':')
                        stanzaName = line.gsub(/:$/, "")
                        next
                    end
                    if line.empty?
                        unless stanzaName == '' || stanzaName == '-'
                            s = readStanza(stanzaName, stanzaLines)
                            s.comment = nextcomment unless s.nil?
                            @stanzas << s unless s.nil?
                            stanzaName = '-'
                            stanzaLines = []
                            nextcomment = ''
                        end
                        next
                    end
                    stanzaLines << line unless stanzaName == '' || stanzaName == '-'
                end
            end
        end
    
        def readStanza(name, lines)
            return nil if name == '' || name == '-'
            h = Hash.new
            lines.each do |line|
                line.strip!
                sAttr, sValue = line.split('=')
                next if sAttr.nil?
                next if sValue.nil?
                sAttr.strip!
                sValue.strip!
                h[sAttr] = sValue
            end
            s = Stanza.new(name, h)
            return s
        end
    
        # character which denotes comments in the file
        attr_accessor :commentChar
        # array of Stanza objects, representing all the stanzas in the file
        attr_accessor :stanzas
        alias clear! empty!
        alias inspect to_s
    end
end


