# coding: utf-8
require 'billit_representers/models/bill'
require './scrapable_classes'
require 'json'

class BillInfo < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@id = ''
		@last_update = HTTParty.get('http://billit.ciudadanointeligente.org/bills/last_update').body
		# @last_update = "30/12/2013"
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
		bill = Billit::Bill.new

		authors = info[:authors].map{|x| x.values}.flatten
		subject_areas = info[:subject_areas].map{|x| x.values}.flatten
		merged_bills = info[:merged_bills].split('/')

		bill.uid = info[:uid]
		bill.title = info[:title]
		bill.creation_date = info[:creation_date]
		bill.source = info[:source]
		bill.initial_chamber = info[:initial_chamber]
		bill.current_priority = info[:current_priority]
		bill.stage = info[:stage]
		bill.sub_stage = info[:sub_stage]
		bill.status = info[:status]
		bill.resulting_document = info[:resulting_document]
		bill.publish_date = info[:publish_date]
		bill.bill_draft_link = info[:bill_draft_link]
		bill.merged_bills = merged_bills
		bill.subject_areas = subject_areas
		bill.authors = authors
		#
		bill.paperworks = info[:paperworks]
		bill.priorities = info[:priorities]
		bill.reports = info[:reports]
		bill.revisions = info[:revisions]
		bill.documents = info[:documents]
		bill.directives = info[:directives]
		bill.remarks = info[:remarks]
		#not present
	    bill.abstract = info[:abstract]
	    bill.law_link = info[:law_link]
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
		info[:source] = xml.at_css('iniciativa').text() if xml.at_css('iniciativa')
		info[:initial_chamber] = xml.at_css('camara_origen').text() if xml.at_css('camara_origen')
		info[:current_priority] = xml.at_css('urgencia_actual').text() if xml.at_css('urgencia_actual')
		info[:stage] = xml.at_css('etapa').text() if xml.at_css('etapa')
		info[:sub_stage] = xml.at_css('subetapa').text() if xml.at_css('subetapa')
		info[:resulting_document] = xml.at_css('leynro').text() if xml.at_css('leynro')
		info[:publish_date] = xml.at_css('diariooficial').text() if xml.at_css('diariooficial')
		info[:status] = xml.at_css('estado').text() if xml.at_css('estado')
		info[:merged_bills] = xml.at_css('refundidos').text() if xml.at_css('refundidos')
		info[:bill_draft_link] = xml.at_css('link_mensaje_mocion').text() if xml.at_css('link_mensaje_mocion')
		hash_fields.keys.each do |field|
			info[field] = get_hash_field_data xml, field
		end
		model_fields.keys.each do |field|
			info[field] = get_model_field_data xml, field
		end
		info
    end

    def get_hash_field_data nokogiri_xml, field
    	field = field.to_sym
    	field_vals = []
    	path = nokogiri_xml.xpath(hash_fields[field][:xpath])
    	path.each do |field_info|
    		field_val = {}
    		hash_fields[field][:sub_fields].each do |sub_field|
    			name = sub_field[:name]
    			css = sub_field[:css]
    			field_val[name] = field_info.at_css(css).text if field_info.at_css(css)
    		end
    		field_vals.push(field_val)
    	end if path
    	field_vals
    end

    def get_model_field_data nokogiri_xml, field
    	field_class = ("Billit::" + field.to_s.classify).constantize
    	# field_class = field.to_s.classify.constantize
    	field_instances = []
    	path = nokogiri_xml.xpath(model_fields[field][:xpath])
    	path.each do |field_info|
    		field_instance = field_class.new
    		model_fields[field][:sub_fields].each do |sub_field|
    			name = sub_field[:name]
    			css = sub_field[:css]
    			field_instance.send name+'=', field_info.at_css(css).text if field_info.at_css(css)
    			# field_instance[name] = field_info.at_css(css).text if field_info.at_css(css)
    		end
    		field_instances.push(field_instance)
    		# field_class.send field+'=', field_val #ta super malo
    	end if path
    	field_instances
    end

    # Used for documents embedded within a bill,
    # posted/put as hashes instead of having their own model and representer
    def model_fields
    	{
    		paperworks: {
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
    		priorities: {
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
	    			},
	    			{
	    				name: 'link',
	    				css: 'LINK_INFORME'
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
	    			},
	    			{
	    				name: 'link',
	    				css: 'LINK_OFICIO'
	    			}
	    		]
    		},
    		directives: {
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
	    			},
	    			{
	    				name: 'link',
	    				css: 'LINK_INDICACION'
	    			}
	    		]
    		},
    		remarks: {
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
    		},
    		revisions: {
    			xpath: '//comparados/comparado',
    			sub_fields: [
    				{
	    				name: 'description',
	    				css: 'COMPARADO'
	    			},
	    			{
	    				name: 'link',
	    				css: 'LINK_COMPARADO'
	    			}
	    		]
    		}
    	}
    end

    # Used for documents embedded within a bill,
    # stored as hashes instead of having their own model and representer
    def hash_fields
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
    		subject_areas: {
    			xpath: '//materias/materia',
    			sub_fields: [
	    			{
	    				name: 'subject_area',
	    				css: 'DESCRIPCION'
	    			}
	    		]
    		}
    	}
    end
end
