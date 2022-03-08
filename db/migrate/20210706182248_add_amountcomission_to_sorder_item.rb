class AddAmountcomissionToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :amountcomission, :float
  end
end
