# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'pdf-reader'
require 'open-uri'

module RestfulApiMethods

	@model =  ''
	@API_url = ''

	def format info
		info
	end

	def put formatted_info
		RestClient.put @API_url + @model + '/' + @id, formatted_info, {:content_type => :json}
	end

	def post formatted_info
		RestClient.post [@API_url, @model].join("/"), formatted_info, :content_type => :json
	end
end

class StorageableInfo
	include RestfulApiMethods

	def initialize(location = '')
		@API_url = 'http://billit.ciudadanointeligente.org'
		# @API_url = 'localhost:3000'
		@location = location
	end

	def process
		doc_locations.each do |doc_location|
			begin
				puts doc_location
				doc = read doc_location
				info = get_info doc
				formatted_info = format info
				save formatted_info
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

