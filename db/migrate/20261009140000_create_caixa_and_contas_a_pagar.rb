# Cash book (SISTGER's cx_num/cx_mov), passenger payments
# (tblOrdemServicoPagtos), bills to pay (the commission/cost payables that
# SISTGER's "Encerrar OS" was meant to create) and closing an order.
class CreateCaixaAndContasAPagar < ActiveRecord::Migration[7.2]
  def change
    create_table :cash_entries do |t|
      t.date :data, null: false
      t.string :tipo, null: false # E entrada, S saída
      t.string :categoria, null: false
      t.string :forma_pagamento, null: false # D dinheiro, O PIX, C débito, R crédito, T transferência
      t.decimal :valor, precision: 12, scale: 2, null: false
      t.string :descricao, null: false
      t.string :requerente
      t.string :documento
      t.string :usuario
      t.references :sorder, foreign_key: { on_delete: :nullify, on_update: :cascade } # imported orders get renumbered
      t.references :sorder_item, foreign_key: { on_delete: :nullify }
      t.integer :sistger_numero
      t.integer :sistger_linha
      t.timestamps
    end
    add_index :cash_entries, :data
    add_index :cash_entries, %i[sistger_numero sistger_linha], unique: true

    create_table :sorder_item_payments do |t|
      t.references :sorder_item, null: false, foreign_key: { on_delete: :cascade }
      t.date :data, null: false
      t.decimal :valor, precision: 12, scale: 2, null: false
      t.string :descricao
      t.string :forma_pagamento
      t.string :usuario
      t.references :cash_entry, foreign_key: { on_delete: :nullify }
      t.integer :sistger_seq
      t.integer :sistger_caixa
      t.timestamps
    end
    add_index :sorder_item_payments, %i[sorder_item_id sistger_seq], unique: true

    create_table :payables do |t|
      t.string :tipo, null: false # comissao_vendedor, comissao_repasse, custo_os, avulsa
      t.string :origem # what generated it: vendedor, repasse, guia, motorista, pedagio, combustivel, despesas
      t.string :descricao, null: false
      t.references :credor, polymorphic: true
      t.string :credor_nome
      t.references :sorder, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.references :sorder_item, foreign_key: { on_delete: :cascade }
      t.decimal :valor, precision: 12, scale: 2, null: false
      t.date :vencimento, null: false
      t.date :pago_em
      t.decimal :valor_pago, precision: 12, scale: 2
      t.string :forma_pagamento
      t.references :cash_entry, foreign_key: { on_delete: :nullify }
      t.string :observacoes
      t.timestamps
    end
    add_index :payables, :vencimento
    add_index :payables, %i[sorder_id sorder_item_id origem], unique: true, nulls_not_distinct: true,
                                                              where: "origem IS NOT NULL", name: "index_payables_on_origem_da_ordem"

    add_column :sorders, :encerrada, :boolean, null: false, default: false
    add_column :sorder_items, :discount, :float
    add_column :sorder_items, :vendor_discount, :float
  end
end
