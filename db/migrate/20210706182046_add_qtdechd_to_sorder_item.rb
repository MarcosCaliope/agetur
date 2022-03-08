class AddQtdechdToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :qtdechd, :integer
  end
end
