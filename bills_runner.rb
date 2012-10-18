# coding: utf-8
require './bills_scrapable_classes'

if !(defined? Test::Unit::TestCase)
	Bills.new.process
end
