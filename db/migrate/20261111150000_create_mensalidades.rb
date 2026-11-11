# Mensalidades das empresas: quanto cada uma paga, quando vence e cada
# pagamento recebido. Registrar o pagamento de um mês avança
# companies.acesso_liberado_ate (ver Mensalidade).
class CreateMensalidades < ActiveRecord::Migration[7.2]
  def change
    change_table :companies, bulk: true do |t|
      t.decimal :mensalidade_valor, precision: 10, scale: 2
      t.integer :dia_vencimento
      t.integer :dias_tolerancia, null: false, default: 5
    end

    create_table :mensalidades do |t|
      t.references :company, null: false, foreign_key: true
      t.date :referencia, null: false
      t.decimal :valor, precision: 10, scale: 2, null: false
      t.date :pago_em, null: false
      t.string :forma
      t.string :observacao
      t.string :registrado_por
      t.timestamps
      t.index %i[company_id referencia], unique: true
    end
  end
end
