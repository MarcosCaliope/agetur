class AddAmountToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :amount, :float
  end
end
