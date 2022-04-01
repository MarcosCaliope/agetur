class RemoveTotchdFromSorder < ActiveRecord::Migration[6.1]
  def change
    remove_column :sorders, :totchd, :string
  end
end
