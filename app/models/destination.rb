class Destination < ApplicationRecord
  belongs_to :state
  has_many :sorders
  has_many :vendor_destinations, dependent: :delete_all
end
