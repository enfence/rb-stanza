#!/usr/bin/ruby

require 'Stanza'

f1 = Stanza::StanzaFile.new('filesystems')
puts f1

a = f1.get_stanza_attr('/nim/spot', 'dev')
puts a

f1.set_stanza_attr('/nim/spot', 'dev', '/dev/lvspot')
b = f1.get_stanza_attr('/nim/spot', 'dev')
puts b

f1.write_to_file('filesystems.new')
