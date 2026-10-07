class AddScanceladoToSorderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :sorder_items, :scancelado, :string
  end
end
