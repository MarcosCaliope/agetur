class CreateSorders < ActiveRecord::Migration[5.2]
  def change
    create_table :sorders do |t|
      t.datetime :data
      t.string :sobservacoes

      t.timestamps
    end
  end
end
