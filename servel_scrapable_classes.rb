# coding: utf-8
require './scrapable_classes'

class ServelDB < StorageableInfo

	def initialize()
                super()
                @location = 'http://consulta.servel.cl'
		@params = 'btnconsulta=SUBMIT&__ASYNCPOST=true&__EVENTARGUMENT=&__EVENTTARGET=&__EVENTVALIDATION=%2FwEWAwL9iqj%2BBQK7%2B6rmDAKVq8qQCQ%3D%3D&__VIEWSTATE=%2FwEPDwUJNzUwMjI5OTkzD2QWAgIDD2QWAgIDDw8WBB4EVGV4dGUeB0VuYWJsZWRoZGRk&hdfl=&txtRUN='
		@ruts
		@file_name
		@xpath_rut = '//*[@id="lbl_run"]'
		@xpath_name = '//*[@id="lbl_nombre"]/text()'
		@xpath_gender = '//*[@id="lbl_sexo"]'
		@xpath_electoral_adress = '//*[@id="lbl_domelect"]/text()'
		@xpath_circunscriptional_adress = '//*[@id="lbl_cirelect"]'
		@xpath_commune = '//*[@id="lbl_comuna"]'
		@xpath_province = '//*[@id="lbl_provincia"]'
		@xpath_region = '//*[@id="lbl_region"]'
		@xpath_table = '//*[@id="lbl_mesa"]'
		@xpath_voting_place = '//*[@id="lbl_localv"]'
		@xpath_voting_place_adress = '//*[@id="lbl_direcvocal"]'
		@xpath_vocal_condition = 'Usted no ha sido designado Vocal de Mesa, sin embargo deberá consultar nuevamente a partir del sábado 13 de octubre por si fue designado en reemplazo de un vocal excusado.'
		@xpath_scrutineer_condition = '//*[@id="lbl_codcolegio"]/text()'
	end

	# doc_locations doesn't have the method each
	def process max, min
		@ruts = Integer(max).downto(Integer(min))
		@file_name = 'servel_'+max.to_s+'-'+min.to_s
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
		#format data
	end

	def get_info params
		RestClient.post @location, params
		html = Nokogiri::HTML(info, nil, 'utf-8')
		#get data with xpath
	end

	def save info
		if !info.nil?
			file = File.open(@file_name, 'a')
			file.write(info)
			file.close()
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
