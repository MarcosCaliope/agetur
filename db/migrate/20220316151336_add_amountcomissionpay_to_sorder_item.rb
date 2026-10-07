class AddAmountcomissionpayToSorderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :sorder_items, :amountcomissionpay, :float
  end
end
