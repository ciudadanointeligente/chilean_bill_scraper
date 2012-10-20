# coding: utf-8
require './scrapable_classes'

class Bills < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@location = 'http://www.senado.cl/wspublico/tramitacion.php?boletin='
		@bills_location = 'bills'
	end

	def doc_locations
		bulletins = parse(read(@bills_location))
		bulletins.map {|b| @location+b}
	end

	def parse doc
		doc_arr = []
		doc.split(/\n/).each do |pair|
			key, val = pair.split(/\t/)
			doc_arr.push(val)
		end
		doc_arr
	end

	def save formatted_info
		#put formatted_info
		p '<info>'
		p formatted_info
		p '</info>'
	end

	def format info
		formatted_info = {
        		:uid => info['uid'],
                        :title => info['title'],
                        :summary => info['summary'],
			:tags => info['tags'],
			:matters => info['matters'],
			:stage => info['stage'],
			:creation_date => info['creation_date'],
			:publish_date => info['publish_date'],
			:authors => info['authors'],
			:origin_chamber => info['origin_chamber'],
			:current_urgency => info['current_urgency'],
			:table_history => info['table_history'],
			:link_law => info['link_law']
		}
	end

	def get_info doc

		info = Hash.new
		xml = Nokogiri::XML(doc)
		info['uid'] = xml.at_css('boletin').text()
		info['title'] = xml.at_css('titulo').text()
		info['creation_date'] = xml.at_css('fecha_ingreso').text()
		info['initiative'] = xml.at_css('iniciativa').text()
		info['origin_chamber'] = xml.at_css('camara_origen').text()
		info['current_urgency'] = xml.at_css('urgencia_actual').text()
		info
        end
end
