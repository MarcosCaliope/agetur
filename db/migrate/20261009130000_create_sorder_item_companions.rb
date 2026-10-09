# SISTGER's tblListaPax: the other people travelling under a passenger item
# (name, document, child, lap infant).
class CreateSorderItemCompanions < ActiveRecord::Migration[7.2]
  def change
    create_table :sorder_item_companions do |t|
      t.references :sorder_item, null: false, foreign_key: { on_delete: :cascade }
      t.references :customer, foreign_key: true
      t.string :snome
      t.string :documenttype
      t.string :document
      t.boolean :chd, null: false, default: false
      t.boolean :colo, null: false, default: false
      t.integer :sistger_seq_adicional
      t.timestamps
    end
    add_index :sorder_item_companions, %i[sorder_item_id sistger_seq_adicional], unique: true
  end
end
