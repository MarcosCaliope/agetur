# Pickup time of a destination's tour at a hotel (SISTGER's
# tblHorarioPasseios), suggested for bookings and order passengers.
class PickupTime < ApplicationRecord
  belongs_to :hotel
  belongs_to :destination

  before_validation { self.hora = hora.to_s.strip.first(5) }

  validates :hora, format: { with: /\A([01]\d|2[0-3]):[0-5]\d\z/, message: "deve estar no formato HH:MM" }
  validates :destination_id, uniqueness: { scope: :hotel_id, message: "já tem horário neste hotel" }

  def self.hora_para(hotel_id, destination_id)
    return if hotel_id.blank? || destination_id.blank?

    find_by(hotel_id: hotel_id, destination_id: destination_id)&.hora
  end
end
