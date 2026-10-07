# Per-destination commission and net prices for a vendor: SISTGER's
# tblVendedorRoteiro ("Comissão por Vendedor e Passeio").
class CreateVendorDestinations < ActiveRecord::Migration[7.2]
  def change
    create_table :vendor_destinations do |t|
      t.references :vendor, null: false, foreign_key: { on_delete: :cascade }
      t.references :destination, null: false, foreign_key: { on_delete: :cascade }
      t.float :commission     # cValorComissao (%)
      t.float :net_adult      # cValorNet
      t.float :net_chd        # cValorNetCHD
      t.float :net_adult_card # cValorNetCartao
      t.float :net_chd_card   # cValorNetCHDCartao
      t.timestamps
    end
    add_index :vendor_destinations, [:vendor_id, :destination_id], unique: true
  end
end
