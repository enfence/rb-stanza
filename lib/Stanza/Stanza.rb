#!/usr/bin/ruby

# Stanza Class
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
    # Class Stanza represents one paragraph from a stanza file.
    # A stanza always has a name and some attributes with values.
    #
    # A basic example of stanza from AIX /etc/filesystems:
    #
    #  /home:
    #         dev = /dev/hd1
    #         mount = true
    #         vfs = jfs2
    # 
    # _/home_ is the name of the stanza. Name always ends with ':'.
    # 
    # _dev_, _mount_ and _vfs_ are the stanza's attributes. Their 
    # values are written after the equal sign. Attribute names
    # usually start after the tabulation character (\t).
    #
    # Every stanza can have comments. Each comment line starts
    # with a comment character in the first position of the string
    # and space. Usual comment character in stanza files is
    # asterisk (*).
    class Stanza
        # creates a new stanza.
        # [name] name of the stanza
        # [attrs] hash of attributes and their values
        # 
        #  a = Stanza::Stanza.new('/home', 
        #                         { 'vfs' => 'jfs2',
        #                           'dev' => '/dev/hd1',
        #                           'mount' => 'true',
        #                         })
        def initialize(name, attrs)
            @name = name
            @attrs = attrs
            @comment = ''
            @commentChar = '*'
        end
    
        # copies all attributes of other stanza
        # all attributes of the current stanza and their
        # values are thrown away
        #
        #  a = Stanza::Stanza.new('/home',
        #                         { 'vfs' => 'jfs2',
        #                           'dev' => '/dev/hd1',
        #                           'mount' => 'true',
        #                         })
        #  b = Stanza::Stanza.new('/usr',
        #                         { 'vfs' => 'jfs2',
        #                           'dev' => '/dev/hd2',
        #                           'mount' => 'true',
        #                         })
        #  a.copy(b)
        #
        # After it _a_ and _b_ have the same stanzas.
        def copy(stanza)
            if stanza.kind_of?(Stanza)
                empty!
                @attrs = stanza.attrs
                @comment = stanza.comment
                @commentChar = stanza.commentChar
            end
        end
    
        # adds a new comment line to the stanza
        #
        #  a.addComment("comment line 1")       #=> "comment line 1\n"
        #  a.addComment("comment line 2")       #=> "comment line 1\ncomment line 2\n"
        def addComment(comment)
            @comment += comment + "\n"
        end
    
        # deletes the whole comment
        # 
        #  a.addComment("comment line")         #=> "comment line\n"
        #  a.delComment()                       #=> ""
        def delComment()
            @comment = ''
        end
    
        # adds or sets attribute's value
        # 
        #  a.addAttribute('check', 'false')     #=> { 'check' => 'false', }
        #  a.addAttribute('mount', 'true')      #=> { 'check' => 'false', 'mount' => 'true', }
        #  a.addAttribute('check', 'true')      #=> { 'check' => 'true', 'mount' => 'true', }
        def addAttribute(name, value)
            @attrs[name] = value
        end
    
        # deletes the attribute from stanza
        #
        #  a.addAttribute('check', 'false')      #=> { 'check' => 'false', }
        #  a.delAttribute('check')               #=> {}
        def delAttribute(name)
            @attrs.delete(name) if attrs.key?(name)
        end
    
        # returns the value of the specified attribute
        #
        #  v = a.getAttribute('check')
        def getAttribute(name)
            return @attrs[name] if attrs.key?(name)
        end
    
        # returns an array with all defined attribute names
        def attributes
            @attrs.keys
        end
    
        # returns an array with values of all defined attributes
        def values
            @attrs.values
        end
    
        # returns a hash of all defined attributes and their values
        def hash
            @attrs
        end
    
        # clears the stanza
        def empty!
            @attrs.clear
            @name = ''
            @comment = ''
        end
    
        # iterates over all attributes and their values of the stanza
        def each            # :yields: key, value
            @attrs.each { |k, v| yield(k, v) }
        end
    
        # iterates over all defined attributes of the stanza
        def each_attribute  # :yields: key
            @attrs.each_key { |k| yield(k) }
        end
    
        # iterates over values of all defined attributes
        def each_value      # :yields: value
            @attrs.each_value { |v| yield(v) }
        end
    
        # checks, if there are defined attributes in the stanza
        def empty?
            @attrs.empty?
        end
    
        # checks, if the stanza has the named attribute
        def has_attribute?(name)
            @attrs.has_key(name)
        end
    
        # merges the otherStanza into the current stanza
        #
        #  s1 = Stanza::Stanza.new('stanza1',
        #                          { 'attr1' => 'value1',
        #                            'attr2' => 'value2',
        #                            'attr3' => 'value3',
        #                          })
        #  s2 = Stanza::Stanza.new('stanza2',
        #                          { 'attr4' => 'value4',
        #                            'attr5' => 'value5',
        #                            'attr2' => 'value3',
        #                          })
        #  s1.merge!(s2)            # => 'stanza1', 
        #                           ##  { 'attr1' => 'value1',
        #                           ##    'attr2' => 'value3',
        #                           ##    'attr3' => 'value3',
        #                           ##    'attr4' => 'value4',
        #                           ##    'attr5' => 'value5',
        #                           ##  }
        def merge!(otherStanza)
            if otherStanza.kind_of?(Stanza)
                @attrs.merge!(otherStanza.attrs)
                @comment += otherStanza.comment
            end
        end
    
        # creates a textual representation of the stanza
        #
        #  s1 = Stanza::Stanza.new('stanza1',
        #                          { 'attr1' => 'value1',
        #                            'attr2' => 'value2',
        #                            'attr3' => 'value3',
        #                          })
        # 
        #  s1.to_s
        # 
        # Output:
        #
        #  stanza1:
        #         attr1 = value1
        #         attr2 = value2
        #         attr3 = value3
        def to_s
            s = ERB.new("<% @comment.lines do |line| %>
<%= @commentChar %> <%= line %>
<% end %>
<%= @name %>:
<% @attrs.each do |key, value| %>
       <%= key %>       = <%= value.chomp %>
<% end %>
", 0, '<>').result(binding)
            return s
        end
    
        # name of the stanza
        attr_accessor :name
        # attributes and their values
        attr_accessor :attrs
        # comment lines for the stanza
        attr_accessor :comment
        # character which denotes comments
        attr_accessor :commentChar

        alias keys attributes
        alias setAttribute addAttribute
        alias attribute getAttribute
        alias key getAttribute
        alias each_attr each_attribute
        alias each_key each_attribute
        alias each_pair each
        alias has_key? has_attribute?
        alias key? has_attribute?
        alias clear! empty!
        alias inspect to_s
    end
end
