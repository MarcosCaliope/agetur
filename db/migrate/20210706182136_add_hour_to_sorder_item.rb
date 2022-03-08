class AddHourToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :hour, :string
  end
end
