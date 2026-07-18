class AddVendorToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorder_items, :vendor, foreign_key: true
  end
end
