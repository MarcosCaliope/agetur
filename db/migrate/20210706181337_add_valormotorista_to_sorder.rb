class AddValormotoristaToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valormotorista, :float
  end
end
