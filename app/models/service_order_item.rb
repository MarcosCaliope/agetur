class ServiceOrderItem < ApplicationRecord
  belongs_to :service_order
  belongs_to :hotel
  belongs_to :vendor
  belongs_to :agency
end
