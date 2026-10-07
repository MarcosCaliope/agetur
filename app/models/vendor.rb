class Vendor < ApplicationRecord
  belongs_to :state, optional: true

  scope :ativos, -> { where(active: true) }
end
