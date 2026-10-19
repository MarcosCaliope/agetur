# Who placed each passenger in an order (SISTGER kept it in
# tblOrdemServicoItensLog), for the "Agendamentos por usuário" report.
# Passengers already placed from a booking take the booking's user.
class AddUsuarioToSorderItems < ActiveRecord::Migration[7.2]
  def up
    add_column :sorder_items, :usuario, :string
    execute <<~SQL
      UPDATE sorder_items SET usuario = bookings.usuario
      FROM booking_items JOIN bookings ON bookings.id = booking_items.booking_id
      WHERE booking_items.sorder_item_id = sorder_items.id AND bookings.usuario IS NOT NULL
    SQL
  end

  def down
    remove_column :sorder_items, :usuario
  end
end
