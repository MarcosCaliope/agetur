# Someone in a booking's pax list (SISTGER's tblListaPaxAGD), copied to
# the order item's pax list when a tour is placed in an order.
class BookingCompanion < ApplicationRecord
  belongs_to :booking

  validates :snome, presence: true

  def atributos_para_ordem
    slice(:snome, :documenttype, :document, :chd, :colo)
  end
end
