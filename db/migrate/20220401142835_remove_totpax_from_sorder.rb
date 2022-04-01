class RemoveTotpaxFromSorder < ActiveRecord::Migration[6.1]
  def change
    remove_column :sorders, :totpax, :string
  end
end
