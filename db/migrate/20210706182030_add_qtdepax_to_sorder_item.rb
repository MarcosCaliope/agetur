class AddQtdepaxToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :qtdepax, :integer
  end
end
