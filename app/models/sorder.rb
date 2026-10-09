class Sorder < ApplicationRecord
    has_many :sorder_items #, inverse_of: :sorders
    accepts_nested_attributes_for :sorder_items, reject_if: :all_blank, allow_destroy: true
    belongs_to :destination
    belongs_to :tourguide
    belongs_to :company
    belongs_to :driver
    belongs_to :vehicle
    has_many :payables

    # Costs of an order that become bills when it's closed: column, origem, description, creditor.
    CUSTOS = [
      [:valorguia, "guia", "Guia", :tourguide], [:valormotorista, "motorista", "Motorista", :driver],
      [:valorpedagio, "pedagio", "Pedágio", nil], [:valorcombustivel, "combustivel", "Combustível", nil],
      [:valordespesas, "despesas", "Despesas", nil]
    ].freeze

    def total_pax
        sorder_items.ativos.sum(:qtdepax)
    end

    def total_chd
        sorder_items.ativos.sum(:qtdechd)
    end

    # Closes the order (SISTGER's "Encerrar OS"): it no longer takes changes
    # or payments, and its unpaid commissions and costs become bills due on
    # `vencimento`. Bills already made by an earlier close are kept.
    def encerrar!(vencimento: data&.to_date || Time.zone.today)
      transaction do
        update!(encerrada: true)
        contas_a_gerar(vencimento).each do |conta|
          payables.create!(conta) unless payables.exists?(sorder_item_id: conta[:sorder_item_id], origem: conta[:origem])
        end
      end
    end

    # Reopens it, dropping the bills its close made that are still unpaid.
    def reabrir!
      transaction do
        payables.abertas.where.not(origem: nil).destroy_all
        update!(encerrada: false)
      end
    end

    def self.ransackable_attributes(auth_object = nil)
      ["company_id", "created_at", "data", "destination_id", "driver_id", "id", "id_value", "sobservacoes", "tourguide_id", "updated_at", "valorcombustivel", "valordespesas", "valorfinalos", "valorguia", "valormotorista", "valoros", "valorpedagio", "vehicle_id"]
    end

    private

    def contas_a_gerar(vencimento)
      base = { vencimento: vencimento }
      contas = sorder_items.ativos.includes(:vendor, :agency).flat_map do |item|
        pax = item.nome_passageiro
        vendedor = item.comissao_a_pagar
        repasse = item.amountcomissionrep.to_f - item.amountcomissionreppay.to_f
        [
          (if vendedor.positive? && item.vendor && !item.vendor.no_commission
             base.merge(tipo: "comissao_vendedor", origem: "vendedor", credor: item.vendor, sorder_item_id: item.id, valor: vendedor.round(2),
                        descricao: "Comissão OS #{id} PAX #{pax}")
           end),
          (if repasse.positive? && item.agency
             base.merge(tipo: "comissao_repasse", origem: "repasse", credor: item.agency, sorder_item_id: item.id, valor: repasse.round(2),
                        descricao: "Comissão de repasse OS #{id} PAX #{pax}")
           end)
        ].compact
      end
      contas + CUSTOS.filter_map do |coluna, origem, nome, credor|
        valor = self[coluna].to_f
        next unless valor.positive?

        base.merge(tipo: "custo_os", origem: origem, sorder_item_id: nil, valor: valor.round(2), descricao: "#{nome} OS #{id}",
                   credor: credor && public_send(credor), credor_nome: (nome unless credor))
      end
    end
end
