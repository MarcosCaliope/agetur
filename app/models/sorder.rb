class Sorder < ApplicationRecord
    include DaEmpresa
    include Auditavel
    has_many :sorder_items #, inverse_of: :sorders
    accepts_nested_attributes_for :sorder_items, reject_if: :all_blank, allow_destroy: true

    # Like SISTGER, removing a saved passenger in the form ("X") cancels it:
    # it leaves the order with its payments and can be brought back
    # (SorderItemsController#reativar). A row not saved yet is just dropped.
    def sorder_items_attributes=(atributos)
      atributos = atributos.to_h if atributos.respond_to?(:permitted?)
      # The shapes nested attributes take: {"0" => {...}}, [{...}] or one {...}.
      if atributos.is_a?(Hash)
        atributos = atributos.key?("id") || atributos.key?(:id) ? [atributos] : atributos.values
      end
      super(atributos.map do |item|
        item = item.to_h.stringify_keys
        next item if item["id"].blank? || !ActiveModel::Type::Boolean.new.cast(item["_destroy"])

        item.except("_destroy").merge("scancelado" => "S")
      end)
    end
    belongs_to :destination
    belongs_to :tourguide
    belongs_to :driver
    belongs_to :vehicle
    has_many :payables
    has_many :edicoes, class_name: "SorderEdicao", dependent: :delete_all

    # lock_version counts changes to the order, its passengers and their
    # payments. Only the edit form checks it (SordersController#update), so
    # Rails' own optimistic locking, which would check every save, is off.
    self.lock_optimistically = false
    before_update { self.lock_version += 1 }

    # Costs of an order that become bills when it's closed: column, origem, description, creditor.
    CUSTOS = [
      [:valorguia, "guia", "Guia", :tourguide], [:valormotorista, "motorista", "Motorista", :driver],
      [:valorpedagio, "pedagio", "Pedágio", nil], [:valorcombustivel, "combustivel", "Combustível", nil],
      [:valordespesas, "despesas", "Despesas", nil]
    ].freeze

    # {order id => [PAX, CHD]} of the active passengers, summed in one query
    # for a whole list. Orders without passengers are missing.
    def self.totais_pax(sorders)
        SorderItem.ativos.where(sorder_id: sorders.select(:id)).group(:sorder_id)
          .pluck(:sorder_id, Arel.sql("COALESCE(SUM(qtdepax), 0)"), Arel.sql("COALESCE(SUM(qtdechd), 0)"))
          .to_h { |id, pax, chd| [id, [pax, chd]] }
    end

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

    # Pulls in the pending booked tours of this destination and date
    # (BookingItem#inclusao_automatica). A passenger typed here with the
    # booking's name is tied to it instead of being added again. Returns
    # [[:incluido | :vinculado | :erro, booking item, error message], ...].
    def incluir_agendamentos!
      return [] if encerrada? || data.nil? || destination_id.nil?

      pendentes = BookingItem.pendentes.where(destination_id: destination_id, data_passeio: data.to_date, inclusao_automatica: true)
                             .includes(:booking).order(:hora, :id).to_a
      return [] if pendentes.empty?

      livres = sorder_items.ativos.where.not(id: BookingItem.where.not(sorder_item_id: nil).select(:sorder_item_id)).to_a
      pendentes.map do |passeio|
        nome = Sorder.nome_comparavel(passeio.booking.snome)
        item = livres.find { |i| Sorder.nome_comparavel(i.nome_passageiro) == nome }
        if item
          livres.delete(item)
          passeio.vincular!(item)
          [:vinculado, passeio]
        else
          passeio.lancar_na_os!(self)
          [:incluido, passeio]
        end
      rescue BookingItem::NaoLancado => e
        [:erro, passeio, e.message]
      end
    end

    # Who has the edit form open (SorderEdicao), to warn the others.
    def registrar_edicao!(usuario)
      SorderEdicao.upsert({ sorder_id: id, usuario: usuario, visto_em: Time.current }, unique_by: %i[sorder_id usuario])
    end

    def encerrar_edicao!(usuario)
      edicoes.where(usuario: usuario).delete_all
    end

    def outros_editando(usuario)
      edicoes.ativas.where.not(usuario: usuario).order(:visto_em)
    end

    # Changes to passengers and their payments move the version too, so a
    # form opened before them can't write over them.
    def self.nova_versao!(id)
      unscoped.where(id: id).update_all("lock_version = lock_version + 1")
    end

    # History (Auditavel, SorderAuditoria), oldest first.
    def auditorias
        SorderAuditoria.where(sorder_id: id).order(:created_at, :id)
    end

    def auditoria_sorder_id = id

    def self.nome_comparavel(nome)
      I18n.transliterate(nome.to_s).downcase.squish
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

    # Closing and reopening are named in the history.
    def acao_auditada
      return "alterou" unless saved_change_to_encerrada?

      encerrada? ? "encerrou" : "reabriu"
    end
end
