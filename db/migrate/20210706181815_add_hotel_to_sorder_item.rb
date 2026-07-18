class AddHotelToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorder_items, :hotel, foreign_key: true
  end
end
