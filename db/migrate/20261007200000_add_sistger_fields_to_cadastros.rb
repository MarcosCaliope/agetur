# Fields of the SISTGER cadastro screens that these tables didn't have.
# Hotels, agencies, guides and drivers share SISTGER's generic screen
# (frmCadGenerico), the same layout as vendors. Left out on purpose:
# customers' freight fields (from SISTGER's CAR system), the company's
# behavior switches (they'd need the matching rules) and vehicles'
# maintenance/fuel modules.
class AddSistgerFieldsToCadastros < ActiveRecord::Migration[7.2]
  def change
    %i[hotels agencies tourguides drivers].each do |tabela|
      change_table tabela, bulk: true do |t|
        t.string :short_name
        t.string :neighborhood
        t.string :city unless tabela == :drivers # drivers already have it
        t.references :state, foreign_key: true
        t.string :zipcode
        t.string :phone2
        t.string :fax
        t.string :contact
        t.string :document
      end
    end

    # Agency: % commission and "Vendedor Correspondente" (iCodVendedor).
    change_table :agencies, bulk: true do |t|
      t.float :commission
      t.references :vendor, foreign_key: true
    end

    # Guides (tblAgenteViagem) and drivers (tblFuncionarios) are imported too.
    %i[tourguides drivers].each do |tabela|
      add_column tabela, :sistger_id, :integer
      add_index tabela, :sistger_id, unique: true
    end

    change_table :customers, bulk: true do |t|
      t.string :state_registration   # scgf (Inscrição)
      t.string :address              # sendereco
      t.string :neighborhood         # sBairro
      t.string :zipcode              # scep
      t.string :phone2               # sfone2
      t.string :fax                  # sfax
      t.string :contact              # scontato
      t.string :website              # sWEB
      t.string :billing_address      # sendcobranca
      t.string :billing_neighborhood # sBairrocob
      t.string :billing_city         # scidcobranca
      t.references :billing_state, foreign_key: { to_table: :states } # sestcobranca
      t.string :billing_zipcode      # scepcobranca
      t.string :billing_phone        # stelcobranca
      t.string :billing_phone2       # sfone2cobranca
      t.string :billing_fax          # sfaxcobranca
    end

    change_table :vehicles, bulk: true do |t|
      t.string :vehicle_type       # sTipo
      t.string :manufacture_year   # sAnoFabricacao (year holds sAnoModelo)
      t.string :capacity           # sCapacidade
      t.string :tank               # sTanque
      t.string :chassis            # sChassi
      t.string :odometer           # sOdometro
      t.string :renavam            # sRenavam
      t.integer :licensing_year    # iAnoLicenciamento
      t.date :acquired_on          # dtAquisicao
      t.string :insurance_kit      # sKitSeguro
    end

    change_table :destinations, bulk: true do |t|
      t.float :value_combo         # nIndCombo
      t.float :value_combo_chd     # nIndCHDCombo
      t.float :value_net_combo     # nNETCombo
      t.float :value_net_combo_chd # nNetComboCHD
    end

    change_table :companies, bulk: true do |t|
      t.string :short_name         # sNomeRed
      t.string :state_registration # sCGF
    end
  end
end
