require 'roar/representer/feature/client'
require 'billit_representers/representers/bill_representer'

class Bill
  include Roar::Representer::Feature::HttpVerbs

  def initialize(*)
    extend Billit::BillRepresenter
    extend Roar::Representer::Feature::Client
    # transport_engine = Roar::Representer::Transport::Faraday
    @persisted = true if @persisted.nil?
  end
end