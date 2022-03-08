class AddValorcombustivelToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valorcombustivel, :float
  end
end
