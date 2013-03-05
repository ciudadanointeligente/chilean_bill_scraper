# coding: utf-8
require './scrapable_classes'
require 'json'

class Bills < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@id = ''
		@location = 'http://www.senado.cl/wspublico/tramitacion.php?boletin='
		@bills_location = 'bills'
	end

	def doc_locations
		bulletins = 8804.downto(1)
		# bulletins = parse(read(@bills_location))
		bulletins.map {|b| @location+b.to_s}
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
		puts "<info>"
		puts formatted_info
		puts "</info>"
		put formatted_info
		# p '<info>'
		# p formatted_info
		# p '</info>'
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
			:link_law => info['link_law'],
			:events => info['events'],
			:urgencies => info['urgencies'],
			:reports => info['reports']
		}.to_json
		@id = info['uid']
		formatted_info
	end


	#
	def get_info doc

		info = Hash.new
		xml = Nokogiri::XML(doc)
		info['uid'] = xml.at_css('boletin').text() if xml.at_css('boletin')
		info['title'] = xml.at_css('titulo').text() if xml.at_css('titulo')
		info['creation_date'] = xml.at_css('fecha_ingreso').text() if xml.at_css('fecha_ingreso')
		info['initiative'] = xml.at_css('iniciativa').text() if xml.at_css('iniciativa')
		info['origin_chamber'] = xml.at_css('camara_origen').text() if xml.at_css('camara_origen')
		info['current_urgency'] = xml.at_css('urgencia_actual').text() if xml.at_css('urgencia_actual')
		info['events'] = get_events xml if xml.xpath('//tramitacion/tramite')
		info['urgencies'] = get_urgencies xml if xml.xpath('//urgencias/urgencia')
		info['reports'] = get_reports xml if xml.xpath('//informes/informe')

		info
    end

    def get_events nokogiri_xml
    	events = []
		tramites = nokogiri_xml.xpath('//tramitacion/tramite')
		tramites.each do |tramite|
			event = {}
			event['session'] = tramite.at_css('SESION').text if tramite.at_css('SESION')
			event['date'] = tramite.at_css('FECHA').text if tramite.at_css('FECHA')
			event['description'] = tramite.at_css('DESCRIPCIONTRAMITE').text if tramite.at_css('DESCRIPCIONTRAMITE')
			event['stage'] = tramite.at_css('ETAPDESCRIPCION').text if tramite.at_css('ETAPDESCRIPCION')
			event['chamber'] = tramite.at_css('CAMARATRAMITE').text if tramite.at_css('CAMARATRAMITE')
			events.push event
		end
		events
	end

    def get_urgencies nokogiri_xml
    	events = []
		tramites = nokogiri_xml.xpath('//urgencias/urgencia')
		tramites.each do |tramite|
			event = {}
			event['type'] = tramite.at_css('TIPO').text if tramite.at_css('TIPO')
			event['entry_date'] = tramite.at_css('FECHAINGRESO').text if tramite.at_css('FECHAINGRESO')
			event['entry_message'] = tramite.at_css('MENSAJEINGRESO').text if tramite.at_css('MENSAJEINGRESO')
			event['entry_chamber'] = tramite.at_css('CAMARAINGRESO').text if tramite.at_css('CAMARAINGRESO')
			event['withdrawal_date'] = tramite.at_css('FECHARETIRO').text if tramite.at_css('FECHARETIRO')
			event['withdrawal_message'] = tramite.at_css('MENSAJERETIRO').text if tramite.at_css('MENSAJERETIRO')
			event['withdrawal_chamber'] = tramite.at_css('CAMARARETIRO').text if tramite.at_css('CAMARARETIRO')
			events.push event
		end
		events
	end

    def get_reports nokogiri_xml
    	events = []
		tramites = nokogiri_xml.xpath('//informes/informe')
		tramites.each do |tramite|
			event = {}
			event['date'] = tramite.at_css('FECHAINFORME').text if tramite.at_css('FECHAINFORME')
			event['step'] = tramite.at_css('TRAMITE').text if tramite.at_css('TRAMITE')
			event['stage'] = tramite.at_css('ETAPA').text if tramite.at_css('ETAPA')
			events.push event
		end
		events
	end
end