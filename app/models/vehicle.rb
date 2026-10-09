class Vehicle < ApplicationRecord
  include Pesquisavel
  pesquisavel_por :license, :brand, :smodel, :vehicle_type, :renavam, :chassis, :city

  belongs_to :state
  has_many :sorders
end
