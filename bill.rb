# require 'roar/representer/feature/client'
require './paperwork'
require 'billit_representers/representers/bill_representer'

class Bill
  # include Roar::Representer::Feature::HttpVerbs
  include Billit::BillRepresenter
  # extend Billit::BillRepresenter
  # include ActiveModel::Validations

  # def initialize(*)
    # extend Roar::Representer::Feature::Client
    # transport_engine = Roar::Representer::Transport::Faraday
    # @persisted = true if @persisted.nil?
  # end
end