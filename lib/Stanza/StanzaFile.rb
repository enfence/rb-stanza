#!/usr/bin/ruby

require 'erb'
require 'tempfile'

module Stanza
    class StanzaFile
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
    
        def read!
            empty!
            readStanzaFile(@fileName)
        end
    
        def write!
            writeStanzaFile(@fileName)
        end
    
        def empty!
            @comment = ''
            @stanzas = []
        end
    
        def readFromFile(file)
            empty!
            readStanzaFile(file)
        end
    
        def writeToFile(filename)
            writeStanzaFile(filename)
        end
    
        def addComment(comment)
            @comment += comment + "\n"
        end
    
        def addStanza(stanza)
            if stanza.kind_of?(Stanza)
                @stanzas << stanza
            end
        end
    
        def setStanza(name, stanza)
            if stanza.kind_of?(Stanza)
                @stanzas.each do |st|
                    st.copy(stanza) if st.name == name
                end
            end
        end
    
        def deleteStanza(name)
            @stanzas.each do |st|
                @stanzas.delete(st) if st.name == name
            end
        end
    
        def getStanza(name)
            @stanzas.each do |st|
                return st if st.name == name
            end
            return nil
        end
    
        def setStanzaAttr(stanzaName, attr, value)
            @stanzas.each do |st|
                if st.name == stanzaName
                    st.setAttribute(attr, value)
                end
            end
        end
    
        def getStanzaAttr(stanzaName, attr)
            @stanzas.each do |st|
                if st.name == stanzaName
                    return st.getAttribute(attr)
                end
            end
        end
    
        def deleteStanzaAttr(stanzaName, attr)
            @stanzas.each do |st|
                if st.name == stanzaName
                    st.delAttribute(attr)
                end
            end
        end
    
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
    
        attr_accessor :commentChar, :stanzas
        alias clear! empty!
        alias inspect to_s
    end
end


