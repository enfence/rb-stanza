#!/usr/bin/ruby

require 'Stanza'

f1 = Stanza::StanzaFile.new('filesystems')
puts f1

a = f1.getStanzaAttr('/nim/spot', 'dev')
puts a

f1.setStanzaAttr('/nim/spot', 'dev', '/dev/lvspot')
b = f1.getStanzaAttr('/nim/spot', 'dev')
puts b

f1.writeToFile('filesystems.new')
