# A vendor's commission and net prices for one destination (SISTGER's
# "Comissão por Vendedor e Passeio"). Destinations without a row use the
# vendor's default commission.
class VendorDestination < ApplicationRecord
  VALORES = %i[net_adult net_chd net_adult_card net_chd_card].freeze

  belongs_to :vendor
  belongs_to :destination

  validates :destination_id, uniqueness: { scope: :vendor_id }
  validates :commission, numericality: { in: 0..100 }, allow_nil: true
  validates(*VALORES, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true)
end
