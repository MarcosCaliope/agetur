class Vendor < ApplicationRecord
  belongs_to :state, optional: true
  has_many :vendor_destinations, dependent: :delete_all

  scope :ativos, -> { where(active: true) }
end
