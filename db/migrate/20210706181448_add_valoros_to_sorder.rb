class AddValorosToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :valoros, :float
  end
end
