class AddValordespesasToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valordespesas, :float
  end
end
