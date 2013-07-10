# coding: utf-8
require 'rubygems'
require 'nokogiri'
# require 'rest-client'
require 'httparty'
require 'pdf-reader'
require 'open-uri'

module RestfulApiMethods

	@model =  ''
	@API_url = ''

	def format info
		info
	end

	def put formatted_info
		HTTParty.put [@API_url, @model, @id].join("/"), formatted_info
	end

	def post formatted_info
		HTTParty.post [@API_url, @model].join("/"), formatted_info
	end
end

class StorageableInfo
	include RestfulApiMethods

	def initialize(location = '')
		# @API_url = 'http://billit.ciudadanointeligente.org'
		@API_url = 'http://localhost:3000'
		@location = location
	end

	def process
		doc_locations.each do |doc_location|
			begin
				puts doc_location
				doc = read doc_location
				puts 'read'
				info = get_info doc
				puts 'got'
				formatted_info = format info
				puts 'formatted'
				save formatted_info
				puts 'saved'
			rescue Exception=>e
				puts e
			end
		end
	end

	def read location = @location
		# it would be better if instead we used
		# mimetype = `file -Ib #{path}`.gsub(/\n/,"")
		if location.class.name != 'String'
			doc = location
		elsif !location.scan(/pdf/).empty?
			doc_pdf = PDF::Reader.new(open(location))
			doc = ''
			doc_pdf.pages.each do |page|
				doc += page.text
			end
		else
			doc = open(location).read
		end
		doc
	end

#----- Undefined Functions -----

	def doc_locations
		[@location]
	end

	def get_info doc
		doc
	end

	def save formatted_info
		put formatted_info
	end
end

