#!/usr/bin/ruby

require 'erb'
require 'tempfile'

module Stanza
    class Stanza
        def initialize(name, attrs)
            @name = name
            @attrs = attrs
            @comment = ''
            @commentChar = '*'
        end
    
        def copy(stanza)
            if stanza.kind_of?(Stanza)
                empty!
                @attrs = stanza.attrs
                @comment = stanza.comment
                @commentChar = stanza.commentChar
            end
        end
    
        def addComment(comment)
            @comment += comment + "\n"
        end
    
        def delComment()
            @comment = ''
        end
    
        def addAttribute(name, value)
            @attrs[name] = value
        end
    
        def delAttribute(name)
            @attrs.delete(name) if attrs.key?(name)
        end
    
        def getAttribute(name)
            return @attrs[name] if attrs.key?(name)
        end
    
        def attributes
            @attrs.keys
        end
    
        def values
            @attrs.values
        end
    
        def hash
            @attrs
        end
    
        def empty!
            @attrs.clear
            @name = ''
            @comment = ''
        end
    
        def each
            @attrs.each { |k, v| yield(k, v) }
        end
    
        def each_attribute
            @attrs.each_key { |k| yield(k) }
        end
    
        def each_value
            @attrs.each_value { |v| yield(v) }
        end
    
        def empty?
            @attrs.empty?
        end
    
        def has_attribute?(name)
            @attrs.has_key(name)
        end
    
        def merge!(otherStanza)
            if otherStanza.kind_of?(Stanza)
                @attrs.merge!(otherStanza.attrs)
                @comment += otherStanza.comment
            end
        end
    
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
    
        attr_accessor :name, :attrs, :comment, :commentChar
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
