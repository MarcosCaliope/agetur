class AddCustomerToServiceOrderItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :service_order_items, :customer, foreign_key: true
  end
end
