# Legacy SISTGER primary keys, so re-running the import updates the records
# it created instead of duplicating them. Records created in this app keep NULL.
class AddSistgerIds < ActiveRecord::Migration[7.2]
  TABLES = %i[companies customers agencies hotels vendors vehicles destinations sorders]

  def change
    TABLES.each do |table|
      add_column table, :sistger_id, :integer
      add_index table, :sistger_id, unique: true
    end

    # Order items are keyed by (iNumero, iSequencial) in SISTGER.
    add_column :sorder_items, :sistger_numero, :integer
    add_column :sorder_items, :sistger_sequencial, :integer
    add_index :sorder_items, [:sistger_numero, :sistger_sequencial], unique: true
  end
end
