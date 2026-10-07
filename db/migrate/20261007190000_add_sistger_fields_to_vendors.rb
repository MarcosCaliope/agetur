# Fields of SISTGER's tblVendedor that vendors didn't have (as edited in
# SISTGER's frmCadGenerico). Left out: iCodCredor (not on the vendor screen)
# and bImpressao (a scratch flag for picking vendors in a report).
class AddSistgerFieldsToVendors < ActiveRecord::Migration[7.2]
  def change
    change_table :vendors, bulk: true do |t|
      t.string :short_name      # sNomeReduzido
      t.string :neighborhood    # sBairro
      t.string :city            # sCidade
      t.references :state, foreign_key: true # sEstado
      t.string :zipcode         # sCep
      t.string :phone2          # sTelefone2
      t.string :fax             # sfax
      t.string :contact         # sContato
      t.string :document        # scnpj (CPF or CNPJ)
      t.string :classification  # sClassificacao
      t.boolean :active, null: false, default: true # bAtivo
    end
  end
end
