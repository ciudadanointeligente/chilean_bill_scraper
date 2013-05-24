# coding: utf-8
require './scrapable_classes'
require 'json'

class Bills < StorageableInfo

	def initialize()
		super()
		@model = 'bills'
		@id = ''
		@last_update = RestClient.get 'billit.ciudadanointeligente.cl/bills/last_update'
		@location = 'http://www.senado.cl/wspublico/tramitacion.php?fecha=' + @last_update
		@bills_location = 'bills'
	end

	def doc_locations
		[@location]
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
		# puts @location
		# puts formatted_info
		post formatted_info
	end

	def format info
		authors = info[:authors].map{|x| x.values}.flatten
		matters = info[:matters].map{|x| x.values}.flatten
		merged = info[:merged].split('/')

		formatted_info = {bill:
			{
	    		:uid => info[:uid],
	            :title => info[:title],
				:creation_date => info[:creation_date],
				:initiative => info[:initiative],
				:origin_chamber => info[:origin_chamber],
				:current_urgency => info[:current_urgency],
				:stage => info[:stage],
				:sub_stage => info[:sub_stage],
				:state => info[:state],
				:law => info[:law],
				:link_law => info[:link_law],
				:merged => merged,
				:matters => matters,
				:authors => authors,
				#
				:events => info[:events],
				:urgencies => info[:urgencies],
				:reports => info[:reports],
				:modifications => info[:modifications],
				:documents => info[:documents],
				:instructions => info[:instructions],
				:observations => info[:observations],
				#not present
				:publish_date => info[:publish_date],
	            :summary => info[:summary],
				:tags => info[:tags]
			}.to_json
		}
		@id = info[:uid]
		formatted_info
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
		info[:link_law] = xml.at_css('diariooficial').text() if xml.at_css('diariooficial')
		info[:state] = xml.at_css('diariooficial').text() if xml.at_css('estado')
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