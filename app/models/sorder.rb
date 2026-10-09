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
    # or payments, and what's left to pay of its commissions and costs
    # becomes bills due on `vencimento`. An open bill from an earlier close
    # or batch payment gets the current value instead of a second bill.
    def encerrar!(vencimento: data&.to_date || Time.zone.today)
      transaction do
        update!(encerrada: true)
        sorder_items.ativos.includes(:vendor, :agency).each do |item|
          Payable::COMISSOES.each_key { |tipo| Payable.de_comissao(item, tipo, vencimento: vencimento)&.save! }
        end
        CUSTOS.each do |coluna, origem, nome, credor|
          saldo = (self[coluna].to_f - payables.pagas.where(origem: origem).sum(:valor_pago).to_f).round(2)
          next unless saldo.positive?

          conta = payables.abertas.find_or_initialize_by(origem: origem, sorder_item_id: nil)
          conta.assign_attributes(tipo: "custo_os", valor: saldo, descricao: "#{nome} OS #{id}",
                                  credor: credor && public_send(credor), credor_nome: (nome unless credor))
          conta.vencimento ||= vencimento
          conta.save!
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
end
