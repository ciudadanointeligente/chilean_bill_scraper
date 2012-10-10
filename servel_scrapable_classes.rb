# coding: utf-8
require './scrapable_classes'

class ServelDB < StorageableInfo

	def initialize()
                super()
                @location = 'http://consulta.servel.cl'
		@params = 'btnconsulta=SUBMIT&__ASYNCPOST=true&__EVENTARGUMENT=&__EVENTTARGET=&__EVENTVALIDATION=%2FwEWAwL9iqj%2BBQK7%2B6rmDAKVq8qQCQ%3D%3D&__VIEWSTATE=%2FwEPDwUJNzUwMjI5OTkzD2QWAgIDD2QWAgIDDw8WBB4EVGV4dGUeB0VuYWJsZWRoZGRk&hdfl=&txtRUN='
		@ruts = 20000000.downto(1000000)
	end

	# doc_locations doesn't have the method each
	def process
		doc_locations do |doc_location|
			begin
				#doc = read doc_location
				info = get_info doc_location
				formatted_info = format info
				save formatted_info
			rescue Exception=>e
				p e
			end
		end
	end

	def doc_locations
		for rut in @ruts
			p rut
			yield @params+rut.to_s+verificador(rut)
		end
	end

	def format info
		html = Nokogiri::HTML(info, nil, 'utf-8')
		info_persona = html.xpath('//*[@id="pnlVista0"]').to_s
		return '<persona>'+info_persona+'</persona>' if !info_persona.empty?
	end

	def get_info params
		RestClient.post @location, params
	end

	def save info
		if !info.nil?
			f = File.open('servel.txt', 'a')
			f.write(info)
			f.close()
		end
	end

	def verificador t
	        v=1
	        s=0
	        for i in (2..9)
	                if i == 8
	                	v=2
	                else v+=1
	        	end
	        	s+=v*(t%10)
	        	t/=10
	        end
	        s = 11 - s%11
	        if s == 11
	        	return 0.to_s
	        elsif s == 10
	        	return "K"
	        else
	        	return s.to_s
	        end
	end
end
