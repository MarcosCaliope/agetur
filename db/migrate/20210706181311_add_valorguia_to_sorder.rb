class AddValorguiaToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valorguia, :float
  end
end
