# coding: utf-8
require 'billit_representers/models/bill'
# require 'billit_representers/models/count'
require './scraper_framework'
require 'json'

class BillScraper < StorageableInfo

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
    @low_chamber_general_vote_location = 'http://opendata.camara.cl/wscamaradiputados.asmx/getVotaciones_Boletin?prmBoletin='
    @low_chamber_detail_vote_location = 'http://opendata.camara.cl/wscamaradiputados.asmx/getVotacion_Detalle?prmVotacionID='
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

    authors = info[:authors].map{|x| x.values}.flatten if info[:authors]
    subject_areas = info[:subject_areas].map{|x| x.values}.flatten if info[:subject_areas]
    merged_bills = info[:merged_bills].split('/') if info[:merged_bills]

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

    bill.motions = info[:motions]

    bill
  end

  def get_info doc
    info = Hash.new
    xml = Nokogiri::XML(doc)
    info[:uid] = xml.at_css('boletin').text() if xml.at_css('boletin')
    @id = info[:uid]
		info[:title] = xml.at_css('titulo').text() if xml.at_css('titulo')
		info[:creation_date] = xml.at_css('fecha_ingreso').text() if xml.at_css('fecha_ingreso')
		info[:source] = xml.at_css('iniciativa').text() if xml.at_css('iniciativa')
		info[:initial_chamber] = xml.at_css('camara_origen').text() if xml.at_css('camara_origen')
		# info[:current_priority] = xml.at_css('urgencia_actual').text() if xml.at_css('urgencia_actual')
		info[:stage] = xml.at_css('etapa').text() if xml.at_css('etapa')
		info[:sub_stage] = xml.at_css('subetapa').text() if xml.at_css('subetapa')
		info[:status] = xml.at_css('estado').text() if xml.at_css('estado')
    info[:resulting_document] = xml.at_css('leynro').text() if xml.at_css('leynro')
    info[:merged_bills] = xml.at_css('refundidos').text() if xml.at_css('refundidos')
    info[:bill_draft_link] = xml.at_css('link_mensaje_mocion').text() if xml.at_css('link_mensaje_mocion')
    info[:publish_date] = xml.at_css('diariooficial').text() if xml.at_css('diariooficial')
		hash_fields.keys.each do |field|
			info[field] = get_hash_field_data xml, field
		end
		model_fields.keys.each do |field|
			info[field] = get_model_field_data xml, field
		end
    get_high_chamber_voting_data xml, info
    get_low_chamber_voting_data info
    info
  end

  def get_low_chamber_voting_data info
    response_voting = HTTParty.get(@low_chamber_general_vote_location + @id, :content_type => :xml)
    response_voting = response_voting['Votaciones']

    if !response_voting.nil?
      if response_voting['Votacion'].is_a? Array
        response_voting['Votacion'].each do |voting|
          votes, pair_ups = get_details_of_voting voting['ID']
          record = get_low_chamber_voting_info voting, votes, pair_ups
          info[:motions] = [] if info[:motions] == nil
          info[:motions] << record
        end
      else
        votes, pair_ups = get_details_of_voting response_voting['Votacion']['ID']
        record = get_low_chamber_voting_info response_voting['Votacion'], votes, pair_ups
        info[:motions] = [] if info[:motions] == nil
        info[:motions] << record
      end
    end
  end

  def get_details_of_voting voting_id
    response = HTTParty.get(@low_chamber_detail_vote_location + voting_id, :content_type => :xml)
    response_votes = response['Votacion']['Votos']['Voto']
    response_pair_up = if response['Votacion']['Pareos'].nil? then nil else response['Votacion']['Pareos']['Pareo'] end
    votes = Array.new
    response_votes.each do |single_vote|
      vote = Hash.new
      vote['voter_id'] = single_vote['Diputado']['Apellido_Paterno'] + " " + single_vote['Diputado']['Apellido_Materno'] + ", " + single_vote['Diputado']['Nombre']
      case single_vote['Opcion']['Codigo']
      when '0' #Negativo
        vote['option'] = "NO"
      when '1' #Afirmativo
        vote['option'] = "SI"
      when '2' #Abstencion
        vote['option'] = "ABSTENCION"
      else
        vote['option'] = "Sin información"
      end
      votes << vote
    end

    if !response_pair_up.nil?
      if response_pair_up.is_a? Array
        pair_ups = Array.new
        i = 1
        response_pair_up.each do |single_pair_up|
          # first pair
          pair_up1 = Hash.new
          pair_up1['voter_id'] = single_pair_up['Diputado1']['Apellido_Paterno'] + " " + single_pair_up['Diputado1']['Apellido_Materno'] + ", " + single_pair_up['Diputado1']['Nombre']
          pair_up1['option'] = "PAREO " + i.to_s #paired
          pair_ups << pair_up1

          # second pair
          pair_up2 = Hash.new
          pair_up2['voter_id'] = single_pair_up['Diputado2']['Apellido_Paterno'] + " " + single_pair_up['Diputado2']['Apellido_Materno'] + ", " + single_pair_up['Diputado2']['Nombre']
          pair_up2['option'] = "PAREO " + i.to_s
          pair_ups << pair_up2
          i = i + 1
        end
      else
        single_pair_up = response_pair_up
        pair_ups = Array.new
        i = 1
        # first pair
        pair_up1 = Hash.new
        pair_up1['voter_id'] = single_pair_up['Diputado1']['Apellido_Paterno'] + " " + single_pair_up['Diputado1']['Apellido_Materno'] + ", " + single_pair_up['Diputado1']['Nombre']
        pair_up1['option'] = "PAREO " + i.to_s #paired
        pair_ups << pair_up1

        # second pair
        pair_up2 = Hash.new
        pair_up2['voter_id'] = single_pair_up['Diputado2']['Apellido_Paterno'] + " " + single_pair_up['Diputado2']['Apellido_Materno'] + ", " + single_pair_up['Diputado2']['Nombre']
        pair_up2['option'] = "PAREO " + i.to_s
        pair_ups << pair_up2
      end
    end
    return votes, pair_ups
  end

  def get_low_chamber_voting_info voting, votes, pair_ups
    motion = BillitMotion.new
    motion.organization = "C.Diputados"
    motion.date = voting['Fecha']
    motion.text = if voting['Articulo'].nil? then 'Sin título' else voting['Articulo'].strip end
    motion.requirement = voting['Quorum']['__content__']
    motion.result = voting['Resultado']['__content__']
    motion.session = voting['Sesion']['ID']
    motion.vote_events = []

    vote_event = BillitVoteEvent.new
    #Counts
    vote_event.counts = []
    count = BillitCount.new
    count.option = "SI"
    count.value = voting['TotalAfirmativos'].to_i
    vote_event.counts << count

    count = BillitCount.new
    count.option = "NO"
    count.value = voting['TotalNegativos'].to_i
    vote_event.counts << count

    count = BillitCount.new
    count.option = "ABSTENCION"
    count.value = voting['TotalAbstenciones'].to_i
    vote_event.counts << count

    count = BillitCount.new
    count.option = "PAREO"
    count.value = pair_ups.count
    vote_event.counts << count

    #Votes
    vote_event.votes = []
    votes_array = votes + pair_ups
    votes_array.each do |single_vote|
      vote = BillitVote.new
      vote.voter_id = single_vote["voter_id"]
      vote.option = single_vote["option"]
      vote_event.votes << vote
    end
    motion.vote_events << vote_event
    return motion
  end

  def get_high_chamber_voting_data nokogiri_xml, info
    require 'active_support/core_ext/hash/conversions'
    hash = Hash.from_xml(nokogiri_xml.to_s)
    if hash['proyectos']['proyecto']['votaciones'].blank?
      info[:motions] = []
      return
    end

    motions = []
    motions_data = hash['proyectos']['proyecto']['votaciones']['votacion']
    motions_data = [motions_data] if motions_data.class == Hash
    motions_data.each do |motion_data|
      motion = BillitMotion.new
      motion.organization = "Senado"
      motion.date = motion_data["FECHA"]
      motion.text = motion_data["TEMA"]
      motion.requirement = motion_data["QUORUM"]
      motion.vote_events = []
      vote_event = BillitVoteEvent.new
      #Counts
      vote_event.counts = []
      ["SI", "NO", "ABSTENCION", "PAREO"].each do |option|
        count = BillitCount.new
        count.option = option
        count.value = motion_data[option]
        vote_event.counts << count
      end
      #Votes
      vote_event.votes = []
      if motion_data["DETALLE_VOTACION"] and motion_data["DETALLE_VOTACION"]["VOTO"]
        votes_hash = motion_data["DETALLE_VOTACION"]["VOTO"]
        votes_hash = [votes_hash] if votes_hash.class == Hash
        votes_hash.each do |vote_hash|
          vote = BillitVote.new
          vote.voter_id = vote_hash["PARLAMENTARIO"]
          vote.option = vote_hash["SELECCION"]
          vote_event.votes << vote
        end
      end
      motion.vote_events << vote_event
      motions << motion
    end
    info[:motions] = motions
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
    "getting model " + field.to_s
    field_class = ("Billit" + field.to_s.classify).constantize
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

  def get_field_data nokogiri_xml, field
    "getting model " + field.to_s
  	field_class = ("Billit" + field.to_s.classify).constantize
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
      },
      motions: {
        xpath: '//votaciones/votacion',
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
            name: 'text',
            css: 'TEMA'
          },
          {
            name: 'yes',
            css: 'SI'
          },
          {
            name: 'no',
            css: 'NO'
          },
          {
            name: 'abstain',
            css: 'ABSTENCION'
          },
          {
            name: 'paired',
            css: 'PAREO'
          },
          {
            name: 'requirement',
            css: 'QUORUM'
          }#,
          # {
          #   name: 'votes',
          #   css: 'DETALLE_VOTACION'
          # }
        ]
      }
    }
  end
end
