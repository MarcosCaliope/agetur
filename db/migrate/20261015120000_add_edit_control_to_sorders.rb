# Concurrent editing of service orders: lock_version refuses a save made
# over a version someone else changed meanwhile (optimistic locking), and
# sorder_edicoes records who has the edit form open, to warn the others.
class AddEditControlToSorders < ActiveRecord::Migration[7.2]
  def change
    add_column :sorders, :lock_version, :integer, default: 0, null: false

    create_table :sorder_edicoes do |t|
      t.references :sorder, null: false, index: false, foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :usuario, null: false
      t.datetime :visto_em, null: false
    end
    add_index :sorder_edicoes, %i[sorder_id usuario], unique: true
  end
end
