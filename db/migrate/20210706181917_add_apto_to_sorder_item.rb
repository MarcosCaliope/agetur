class AddAptoToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :apto, :string
  end
end
