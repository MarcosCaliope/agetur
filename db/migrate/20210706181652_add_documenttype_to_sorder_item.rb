class AddDocumenttypeToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :documenttype, :string
  end
end
