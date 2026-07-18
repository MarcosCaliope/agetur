class AddAgencyToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorder_items, :agency, foreign_key: true
  end
end
