class AddDocumentToSorderItem < ActiveRecord::Migration[5.2]
  def change
    add_column :sorder_items, :document, :string
  end
end
