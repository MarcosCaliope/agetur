# SISTGER's tblVendedor.bComissao, the "Não Pagar Comissão" checkbox of its
# vendor screen.
class AddNoCommissionToVendors < ActiveRecord::Migration[7.2]
  def change
    add_column :vendors, :no_commission, :boolean, null: false, default: false
  end
end
