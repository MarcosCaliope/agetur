# Who did what to an order, its passengers, their pax lists and payments
# (SISTGER copied tblOrdemServicoItens before and after each change). Only
# the changed fields are kept, as {campo: [antes, depois]}; a deletion keeps
# the whole record. No foreign key to sorders, so a deleted order's history
# stays; SistgerImport#renumerar_ordens renumbers it with the orders.
class CreateSorderAuditorias < ActiveRecord::Migration[7.2]
  def change
    create_table :sorder_auditorias do |t|
      t.bigint :sorder_id, null: false
      t.references :company, null: false, foreign_key: true
      t.string :registro_type, null: false
      t.bigint :registro_id
      t.string :descricao
      t.string :acao, null: false
      t.string :usuario
      t.jsonb :alteracoes, null: false, default: {}
      t.datetime :created_at, null: false
      t.index %i[sorder_id created_at]
    end
  end
end
