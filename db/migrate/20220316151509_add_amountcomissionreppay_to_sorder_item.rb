class AddAmountcomissionreppayToSorderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :sorder_items, :amountcomissionreppay, :float
  end
end
