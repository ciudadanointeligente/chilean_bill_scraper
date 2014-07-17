# test con 1 author, subject_areas, merged
# test con muchos
require './bill_scraper'
require 'webmock/rspec'
require 'byebug'

describe BillScraper do
  before :each do
    stub_request(:get, "http://billit.ciudadanointeligente.org/bills/last_update").
      to_return(:status => 200, :body => "", :headers => {})
    stub_request(:get, "http://opendata.camara.cl/wscamaradiputados.asmx/getVotaciones_Boletin?prmBoletin=8292-13").
      to_return(:status => 200, :body => File.open("./spec/low_chamber_general_full"), :headers => {
         'Accept' => 'application/xml',
         'Content-type' => 'application/xml'
       })
    stub_request(:get, "http://opendata.camara.cl/wscamaradiputados.asmx/getVotacion_Detalle?prmVotacionID=15842").
      to_return(:status => 200, :body => File.open("./spec/low_chamber_detail_1"), :headers => {
         'Accept' => 'application/xml',
         'Content-type' => 'application/xml'
       })
    stub_request(:get, "http://opendata.camara.cl/wscamaradiputados.asmx/getVotacion_Detalle?prmVotacionID=15843").
      to_return(:status => 200, :body => File.open("./spec/low_chamber_detail_2"), :headers => {
         'Accept' => 'application/xml',
         'Content-type' => 'application/xml'
       })
  end
  it "stubs doc_locations method" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    expect(bill_info.doc_locations).to eq(["./spec/high_chamber_full"])
  end
  it "reads the local doc" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    expect(doc).to be_a String
  end
  it "retrieves the info from the source" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    info = bill_info.get_info doc
    expect(info).to be_a Hash
    expect(info).not_to be_empty
  end
  it "formats the retrieved info" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    info = bill_info.get_info doc
    formatted_info = bill_info.format info
    expect(formatted_info).to be_a Billit::Bill
  end
  it "formats hashes info" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    info = bill_info.get_info doc
    formatted_info = bill_info.format info
    expect(formatted_info.authors).to be_an Array
    expect(formatted_info.authors.count).to eq(2)
    expect(formatted_info.subject_areas).to be_an Array
    expect(formatted_info.subject_areas.count).to eq(2)
    expect(formatted_info.merged_bills).to be_an Array
    expect(formatted_info.merged_bills.count).to eq(2)
  end
  it "formats voting info" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    info = bill_info.get_info doc
    formatted_info = bill_info.format info
    expect(formatted_info.motions).to be_an Array
    expect(formatted_info.motions.count).to eq(4)
  end
  it "formats high chamber voting info" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    info = bill_info.get_info doc
    formatted_info = bill_info.format info
    high_chamber_motion = nil
    formatted_info.motions.each do |motion|
      if motion.organization == "Senado"
        high_chamber_motion = motion
        break
      end
    end
    expect(high_chamber_motion.organization).to eq("Senado")
    expect(high_chamber_motion.vote_events.first.counts.first).to be_an BillitCount
    expect(high_chamber_motion.vote_events.first.counts.count).to eq(4)
    expect(high_chamber_motion.vote_events.first.votes.first).to be_a BillitVote
    expect(high_chamber_motion.vote_events.first.votes.count).to eq(2)
  end
  it "formats low chamber voting info" do
    bill_info = BillScraper.new
    bill_info.stub(:doc_locations){["./spec/high_chamber_full"]}
    doc = bill_info.read bill_info.doc_locations.first
    info = bill_info.get_info doc
    formatted_info = bill_info.format info
    low_chamber_motion = nil
    formatted_info.motions.each do |motion|
      puts motion.organization
      if motion.organization == "C.Diputados"
        low_chamber_motion = motion
        break
      end
    end
    expect(low_chamber_motion.organization).to eq("C.Diputados")
    expect(low_chamber_motion.vote_events.first.counts.first).to be_an BillitCount
    expect(low_chamber_motion.vote_events.first.counts.count).to eq(4)
    expect(low_chamber_motion.vote_events.first.votes.first).to be_a BillitVote
    expect(low_chamber_motion.vote_events.first.votes.count).to eq(4)
  end
  xit "formats objects info" do
  end
  xit "saves the info" do
    # bill_info.stub(:save){}
    # bill_info.save formatted_info
  end
  context "with one element information" do
    before :each do
      stub_request(:get, "http://billit.ciudadanointeligente.org/bills/last_update").
        to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "http://opendata.camara.cl/wscamaradiputados.asmx/getVotaciones_Boletin?prmBoletin=8292-13").
        to_return(:status => 200, :body => File.open("./spec/low_chamber_general_single"), :headers => {
           'Accept' => 'application/xml',
           'Content-type' => 'application/xml'
         })
      stub_request(:get, "http://opendata.camara.cl/wscamaradiputados.asmx/getVotacion_Detalle?prmVotacionID=15842").
      to_return(:status => 200, :body => File.open("./spec/low_chamber_detail_1"), :headers => {
           'Accept' => 'application/xml',
           'Content-type' => 'application/xml'
         })
    end
    it "formats hashes info" do
      bill_info = BillScraper.new
      bill_info.stub(:doc_locations){["./spec/high_chamber_single"]}
      doc = bill_info.read bill_info.doc_locations.first
      info = bill_info.get_info doc
      formatted_info = bill_info.format info
      expect(formatted_info.authors).to be_an Array
      expect(formatted_info.authors.count).to eq(1)
      expect(formatted_info.subject_areas).to be_an Array
      expect(formatted_info.subject_areas.count).to eq(1)
      expect(formatted_info.merged_bills).to be_an Array
      expect(formatted_info.merged_bills.count).to eq(1)
    end
    it "formats voting info" do
      bill_info = BillScraper.new
      bill_info.stub(:doc_locations){["./spec/high_chamber_single"]}
      doc = bill_info.read bill_info.doc_locations.first
      info = bill_info.get_info doc
      formatted_info = bill_info.format info
      expect(formatted_info.motions).to be_an Array
      expect(formatted_info.motions.count).to eq(2)
      motion_organizations = []
      formatted_info.motions.each do |motion|
        motion_organizations << motion.organization
      end
      expect(motion_organizations.include?("C.Diputados")).to be_true
      expect(motion_organizations.include?("Senado")).to be_true
    end
  end
  context "with empty information" do
    before :each do
      stub_request(:get, "http://billit.ciudadanointeligente.org/bills/last_update").
        to_return(:status => 200, :body => "", :headers => {})
      stub_request(:get, "http://opendata.camara.cl/wscamaradiputados.asmx/getVotaciones_Boletin?prmBoletin=8292-13").
        to_return(:status => 200, :body => File.open("./spec/low_chamber_general_empty"), :headers => {
           'Accept' => 'application/xml',
          'Content-type' => 'application/xml'
        })
    end
    it "formats hashes info" do
      bill_info = BillScraper.new
      bill_info.stub(:doc_locations){["./spec/high_chamber_empty"]}
      doc = bill_info.read bill_info.doc_locations.first
      info = bill_info.get_info doc      
      formatted_info = bill_info.format info
      expect(formatted_info.authors).to be_an Array
      expect(formatted_info.authors.count).to eq(0)
      expect(formatted_info.subject_areas).to be_an Array
      expect(formatted_info.subject_areas.count).to eq(0)
      expect(formatted_info.merged_bills).to be_an Array
      expect(formatted_info.merged_bills.count).to eq(0)
    end
    it "formats voting info" do
      bill_info = BillScraper.new
      bill_info.stub(:doc_locations){["./spec/high_chamber_empty"]}
      doc = bill_info.read bill_info.doc_locations.first
      info = bill_info.get_info doc
      formatted_info = bill_info.format info
      expect(formatted_info.motions).to be_an Array
      expect(formatted_info.motions.count).to eq(0)
    end
  end
end