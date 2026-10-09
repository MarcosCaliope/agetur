# Imported orders take SISTGER's iNumero as their id, so renumbering an order
# must carry its passengers along.
class CascadeSorderIdUpdatesToItems < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :sorder_items, :sorders
    add_foreign_key :sorder_items, :sorders, on_update: :cascade
  end
end
