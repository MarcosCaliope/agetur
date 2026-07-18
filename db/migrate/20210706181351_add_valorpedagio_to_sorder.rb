class AddValorpedagioToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valorpedagio, :float
  end
end
