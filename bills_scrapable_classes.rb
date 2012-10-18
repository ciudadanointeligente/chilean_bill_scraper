# coding: utf-8
require './scrapable_classes'

class Bills < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@location = 'http://www.senado.cl/wspublico/tramitacion.php?boletin='
	end

	def save formatted_info
		#put formatted_info
		p formatted_info
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

	def doc_locations
		bulletins = ['8091-21', '8011-05']
		bulletins.map {|b| @location+b}
	end

	def get_info doc

		info = Hash.new
		xml = Nokogiri::XML(doc)
		p xml.at_css('boletin').text()
		info['uid'] = xml.at_css('boletin').text()
		info['title'] = xml.at_css('titulo').text()
		info['creation_date'] = xml.at_css('fecha_ingreso').text()
		info['initiative'] = xml.at_css('iniciativa').text()
		info['origin_chamber'] = xml.at_css('camara_origen').text()
		info['current_urgency'] = xml.at_css('urgencia_actual').text()
		info
        end
end
