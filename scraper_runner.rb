# coding: utf-8
require './bill_scraper'

if !(defined? Test::Unit::TestCase)
	BillScraper.new.process
end
