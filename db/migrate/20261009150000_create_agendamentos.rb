# Bookings (SISTGER's frmCadAgendamentos: tblAgendamentos, tblAgendamentosItens,
# tblListaPaxAGD) and pickup times per hotel and destination
# (tblHorarioPasseios).
class CreateAgendamentos < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.date :data, null: false
      t.string :snome, null: false
      t.references :customer, foreign_key: true
      t.string :telefone
      t.references :hotel, foreign_key: true
      t.string :apto
      t.string :documenttype
      t.string :document
      t.references :vendor, null: false, foreign_key: true
      t.string :forma_pagamento
      t.integer :parcelas
      t.string :observacoes
      t.string :usuario
      t.timestamps
    end

    create_table :booking_items do |t|
      t.references :booking, null: false, foreign_key: { on_delete: :cascade }
      t.references :destination, null: false, foreign_key: true
      t.date :data_passeio, null: false
      t.string :hora
      t.integer :qtdepax, null: false, default: 1
      t.integer :qtdechd, null: false, default: 0
      t.decimal :valor, precision: 12, scale: 2, null: false, default: 0
      t.boolean :cancelado, null: false, default: false
      t.string :observacao
      t.references :sorder_item, foreign_key: { on_delete: :nullify } # set once it's in an order
      t.timestamps
    end
    add_index :booking_items, :data_passeio

    create_table :booking_companions do |t|
      t.references :booking, null: false, foreign_key: { on_delete: :cascade }
      t.string :snome, null: false
      t.string :documenttype
      t.string :document
      t.boolean :chd, null: false, default: false
      t.boolean :colo, null: false, default: false
      t.timestamps
    end

    # A booking's down payment is a passenger payment that later moves to the order item.
    change_column_null :sorder_item_payments, :sorder_item_id, true
    add_reference :sorder_item_payments, :booking_item, foreign_key: { on_delete: :cascade }

    create_table :pickup_times do |t|
      t.references :hotel, null: false, foreign_key: { on_delete: :cascade }
      t.references :destination, null: false, foreign_key: { on_delete: :cascade }
      t.string :hora, null: false
      t.timestamps
    end
    add_index :pickup_times, %i[hotel_id destination_id], unique: true
  end
end
