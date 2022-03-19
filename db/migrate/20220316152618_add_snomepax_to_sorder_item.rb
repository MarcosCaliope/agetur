class AddSnomepaxToSorderItem < ActiveRecord::Migration[6.1]
  def change
    add_column :sorder_items, :snomepax, :string
  end
end
