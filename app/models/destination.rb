class Destination < ApplicationRecord
  include DaEmpresa
  include Pesquisavel
  pesquisavel_por :description

  belongs_to :state
  has_many :sorders
  has_many :vendor_destinations, dependent: :delete_all
end
