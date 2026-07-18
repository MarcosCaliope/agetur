class AddPhoneToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :phone, :string
  end
end
