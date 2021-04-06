class CreateServiceOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :service_orders do |t|
      t.datetime :data
      t.references :destination, foreign_key: true
      t.references :tourguide, foreign_key: true
      t.references :driver, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.float :valorguia
      t.float :valormotorista
      t.float :valorpedagio
      t.float :valordespesas
      t.float :valorcombustivel
      t.float :valoros
      t.float :valorfinalos
      t.boolean :bpagto
      t.boolean :bcancelado
      t.integer :icapacidade
      t.integer :ibloqueio
      t.integer :iflgaberto
      t.integer :ilitros
      t.string :sobservacoes
      t.string :sodometroinicio
      t.string :sodometrofim

      t.timestamps
    end
  end
end
