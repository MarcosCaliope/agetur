class AddValorfinalosToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valorfinalos, :float
  end
end
