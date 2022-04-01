class RemoveIntegerFromSorder < ActiveRecord::Migration[6.1]
  def change
    remove_column :sorders, :integer, :string
  end
end
