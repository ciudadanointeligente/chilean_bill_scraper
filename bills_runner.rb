# coding: utf-8
require './bill_info'

if !(defined? Test::Unit::TestCase)
	BillInfo.new.process
end
