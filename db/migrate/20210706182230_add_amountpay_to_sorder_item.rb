class AddAmountpayToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :amountpay, :float
  end
end
