class AddAmountcomissionrepToSorderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :sorder_items, :amountcomissionrep, :float
  end
end
