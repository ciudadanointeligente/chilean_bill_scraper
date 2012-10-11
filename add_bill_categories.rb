# coding: utf-8
require './scrapable_classes'

if !(defined? Test::Unit::TestCase)
	BillCategory.new.process
end
