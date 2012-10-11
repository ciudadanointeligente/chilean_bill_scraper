# coding: utf-8
require './servel_scrapable_classes'

if !(defined? Test::Unit::TestCase)
	ServelDB.new.process 18000000, 17999990
end
