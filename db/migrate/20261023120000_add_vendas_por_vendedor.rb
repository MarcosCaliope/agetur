# Vendedores com login (users.vendor_id) e sinais informados por eles, que
# ficam "a conferir" até o escritório confirmar (sorder_item_payments.situacao).
class AddVendasPorVendedor < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :vendor, foreign_key: true
    change_table :sorder_item_payments, bulk: true do |t|
      t.string :situacao
      t.string :conferido_por
      t.datetime :conferido_em
      t.string :motivo_recusa
      t.index :situacao
    end
  end
end
