class ServiceOrder < ApplicationRecord
  belongs_to :destination
  belongs_to :tourguide
  belongs_to :driver
  belongs_to :vehicle
end
