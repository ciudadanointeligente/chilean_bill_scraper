# coding: utf-8
require './bill'
require './scrapable_classes'
require 'json'

class BillInfo < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@id = ''
		@last_update = HTTParty.get('http://billit.ciudadanointeligente.org/bills/last_update').body
		@update_location = 'http://www.senado.cl/wspublico/tramitacion.php?fecha='
		@location = 'http://www.senado.cl/wspublico/tramitacion.php?boletin='
		@bills_location = 'bills'
		@format = 'application/json'
	end

	def doc_locations
		doc = HTTParty.get(@update_location + @last_update).body
		xml = Nokogiri::XML(doc)
		projects = xml.xpath('//boletin').map {|x| x.text}
		locations = projects.map {|x| @location + x.split('-')[0]}
	end

	def save bill
		result_code = HTTParty.get([@API_url, @model, @id].join("/"), headers: {"Accept"=>"*/*"}).code#{|response, request, result| result.code }
		if result_code == 200
			puts "-------- 200 ---------"
			put bill
		else
			puts "-------- 404 ---------"
			post bill
		end
	end

	def put bill
	  bill.put([@API_url, @model, bill.uid].join("/"), @format)
	end

	def post bill
	  bill.post([@API_url, @model].join("/"), @format)
	end

	def format info
		bill = Bill.new

		authors = info[:authors].map{|x| x.values}.flatten
		matters = info[:matters].map{|x| x.values}.flatten
		merged = info[:merged].split('/')

		bill.uid = info[:uid]
		bill.title = info[:title]
		bill.creation_date = info[:creation_date]
		bill.initiative = info[:initiative]
		bill.origin_chamber = info[:origin_chamber]
		bill.current_urgency = info[:current_urgency]
		bill.stage = info[:stage]
		bill.sub_stage = info[:sub_stage]
		bill.state = info[:state]
		bill.law = info[:law]
		bill.publish_date = info[:publish_date]
		bill.merged = merged
		bill.matters = matters
		bill.authors = authors
		#
		bill.events = info[:events]
		bill.urgencies = info[:urgencies]
		bill.reports = info[:reports]
		bill.modifications = info[:modifications]
		bill.documents = info[:documents]
		bill.instructions = info[:instructions]
		bill.observations = info[:observations]
		#not present
	    bill.summary = info[:summary]
	    bill.link_law = info[:link_law]
		bill.tags = info[:tags]

		@id = info[:uid]
		bill
	end

    def get_info doc

		info = Hash.new
		xml = Nokogiri::XML(doc)
		info[:uid] = xml.at_css('boletin').text() if xml.at_css('boletin')
		info[:title] = xml.at_css('titulo').text() if xml.at_css('titulo')
		info[:creation_date] = xml.at_css('fecha_ingreso').text() if xml.at_css('fecha_ingreso')
		info[:initiative] = xml.at_css('iniciativa').text() if xml.at_css('iniciativa')
		info[:origin_chamber] = xml.at_css('camara_origen').text() if xml.at_css('camara_origen')
		info[:current_urgency] = xml.at_css('urgencia_actual').text() if xml.at_css('urgencia_actual')
		info[:stage] = xml.at_css('etapa').text() if xml.at_css('etapa')
		info[:sub_stage] = xml.at_css('subetapa').text() if xml.at_css('subetapa')
		info[:law] = xml.at_css('leynro').text() if xml.at_css('leynro')
		info[:publish_date] = xml.at_css('diariooficial').text() if xml.at_css('diariooficial')
		info[:state] = xml.at_css('estado').text() if xml.at_css('estado')
		info[:merged] = xml.at_css('refundidos').text() if xml.at_css('refundidos')
		fields.keys.each do |field|
			info[field] = get_field_data xml, field
		end
		info
    end

    def get_field_data nokogiri_xml, field
    	field = field.to_sym
    	field_vals = []
    	path = nokogiri_xml.xpath(fields[field][:xpath])
    	path.each do |field_instance|
    		field_val = {}
    		fields[field][:sub_fields].each do |sub_field|
    			name = sub_field[:name]
    			css = sub_field[:css]
    			field_val[name] = field_instance.at_css(css).text if field_instance.at_css(css)
    		end
    		field_vals.push(field_val)
    	end if path
    	field_vals
    end

    def fields
    	{
    		authors: {
    			xpath: '//autores/autor',
    			sub_fields: [
    				{
	    				name: 'author',
	    				css: 'PARLAMENTARIO'
	    			}
	    		]
    		},
    		matters: {
    			xpath: '//materias/materia',
    			sub_fields: [
	    			{
	    				name: 'matter',
	    				css: 'DESCRIPCION'
	    			}
	    		]
    		},
    		events: {
    			xpath: '//tramitacion/tramite',
    			sub_fields: [
    				{
	    				name: 'session',
	    				css: 'SESION'
	    			},
	    			{
	    				name: 'date',
	    				css: 'FECHA'
	    			},
	    			{
	    				name: 'description',
	    				css: 'DESCRIPCIONTRAMITE'
	    			},
	    			{
	    				name: 'stage',
	    				css: 'ETAPDESCRIPCION'
	    			},
	    			{
	    				name: 'chamber',
	    				css: 'CAMARATRAMITE'
	    			}
    		 	]
    		},
    		urgencies: {
    			xpath: '//urgencias/urgencia',
    			sub_fields: [
	    			{
	    				name: 'type',
	    				css: 'TIPO'
	    			},
	    			{
	    				name: 'entry_date',
	    				css: 'FECHAINGRESO'
	    			},
	    			{
	    				name: 'entry_message',
	    				css: 'MENSAJEINGRESO'
	    			},
	    			{
	    				name: 'entry_chamber',
	    				css: 'CAMARAINGRESO'
	    			},
	    			{
	    				name: 'withdrawal_date',
	    				css: 'FECHARETIRO'
	    			},
	    			{
	    				name: 'withdrawal_message',
	    				css: 'MENSAJERETIRO'
	    			},
	    			{
	    				name: 'withdrawal_chamber',
	    				css: 'CAMARARETIRO'
	    			}
	    		]
    		},
    		reports: {
    			xpath: '//informes/informe',
    			sub_fields: [
	    			{
	    				name: 'date',
	    				css: 'FECHAINFORME'
	    			},
	    			{
	    				name: 'step',
	    				css: 'TRAMITE'
	    			},
	    			{
	    				name: 'stage',
	    				css: 'ETAPA'
	    			}
	    		]
    		},
    		modifications: {
    			xpath: '//comparados/comparado',
    			sub_fields: [
    				{
	    				name: 'modification',
	    				css: 'COMPARADO'
	    			}
	    		]
    		},
    		documents: {
    			xpath: '//oficios/oficio',
    			sub_fields: [
	    			{
	    				name: 'number',
	    				css: 'NUMERO'
	    			},
	    			{
	    				name: 'date',
	    				css: 'FECHA'
	    			},
	    			{
	    				name: 'step',
	    				css: 'TRAMITE'
	    			},
	    			{
	    				name: 'stage',
	    				css: 'ETAPA'
	    			},
	    			{
	    				name: 'type',
	    				css: 'TIPO'
	    			},
	    			{
	    				name: 'chamber',
	    				css: 'CAMARA'
	    			}
	    		]
    		},
    		instructions: {
    			xpath: '//indicaciones/indicacion',
    			sub_fields: [
	    			{
	    				name: 'date',
	    				css: 'FECHA'
	    			},
	    			{
	    				name: 'step',
	    				css: 'TRAMITE'
	    			},
	    			{
	    				name: 'stage',
	    				css: 'ETAPA'
	    			}
	    		]
    		},
    		observations: {
    			xpath: '//observaciones/observacion',
    			sub_fields: [
	    			{
	    				name: 'date',
	    				css: 'FECHA'
	    			},
	    			{
	    				name: 'step',
	    				css: 'TRAMITE'
	    			},
	    			{
	    				name: 'stage',
	    				css: 'ETAPA'
	    			}
	    		]
    		}
    	}
    end
end