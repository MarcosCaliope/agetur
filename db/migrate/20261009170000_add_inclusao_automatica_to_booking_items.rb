# Saving an order pulls in the pending booked tours of its destination and
# date. A tour taken out of an order isn't pulled in again by itself.
class AddInclusaoAutomaticaToBookingItems < ActiveRecord::Migration[7.2]
  def change
    add_column :booking_items, :inclusao_automatica, :boolean, null: false, default: true
  end
end
