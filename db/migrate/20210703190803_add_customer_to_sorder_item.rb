class AddCustomerToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorder_items, :customer, foreign_key: true
  end
end
