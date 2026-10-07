class Sorder < ApplicationRecord
    has_many :sorder_items #, inverse_of: :sorders
    accepts_nested_attributes_for :sorder_items, reject_if: :all_blank, allow_destroy: true
    belongs_to :destination
    belongs_to :tourguide
    belongs_to :company
    belongs_to :driver
    belongs_to :vehicle

    def total_pax
        sorder_items.ativos.sum(:qtdepax)
    end

    def total_chd
        sorder_items.ativos.sum(:qtdechd)
    end

    def self.ransackable_attributes(auth_object = nil)
      ["company_id", "created_at", "data", "destination_id", "driver_id", "id", "id_value", "sobservacoes", "tourguide_id", "updated_at", "valorcombustivel", "valordespesas", "valorfinalos", "valorguia", "valormotorista", "valoros", "valorpedagio", "vehicle_id"]
    end
end
