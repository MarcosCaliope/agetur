class SorderItem < ApplicationRecord
  class NaoMovimentado < StandardError; end
  include DaEmpresa
  da_empresa via: :sorder
  include Auditavel
  belongs_to :sorder
  # Any change to a passenger moves the order's version (Sorder.nova_versao!).
  after_save { Sorder.nova_versao!(sorder_id) }
  after_destroy { Sorder.nova_versao!(sorder_id) }
  after_update :registrar_transferencia, if: :saved_change_to_sorder_id?
  belongs_to :customer, optional: true
  belongs_to :hotel, optional: true
  belongs_to :vendor, optional: true
  belongs_to :agency, optional: true
  # Down payments taken on a booking go back to it when the item is removed.
  before_destroy :devolver_sinais_ao_agendamento, prepend: true
  has_many :pagamentos, -> { order(:data, :id) }, class_name: "SorderItemPayment", dependent: :destroy
  has_one :booking_item # the booked tour it was placed from, if any
  has_many :companions, -> { order(:sistger_seq_adicional, :id) }, class_name: "SorderItemCompanion", inverse_of: :sorder_item,
                        dependent: :delete_all
  accepts_nested_attributes_for :companions, reject_if: ->(atributos) { atributos["snome"].blank? }, allow_destroy: true

  # How the passenger pays (SISTGER's sFormaPagto), printed by order model 3.
  # PIX isn't in SISTGER; it takes the cash book's key for it ("O", CashEntry::FORMAS).
  FORMAS_PAGAMENTO = { "D" => "Dinheiro", "O" => "PIX", "Q" => "Cheque", "C" => "Cartão", "P" => "Cartão parcelado" }.freeze

  # Left out of a copy (#copiar_para!): what was received or paid belongs
  # to the original, and the copy is a passenger of this app.
  NAO_COPIADOS = %w[id sorder_id company_id created_at updated_at amountpay amountcomissionpay amountcomissionreppay
                    scancelado sistger_numero sistger_sequencial usuario].freeze

  # scancelado is "S"/"N"; items saved before the column existed are blank
  # and count as not cancelled.
  scope :ativos, -> { where(scancelado: [nil, "", "N"]) }

  validates :forma_pagamento, inclusion: { in: FORMAS_PAGAMENTO.keys }, allow_blank: true
  validate :vendedor_ativo, if: -> { vendor_id.present? && vendor_id_changed? }

  # Like SISTGER: a blank time takes the tour's pickup time at the hotel.
  before_validation { self.hour = PickupTime.hora_para(hotel_id, sorder&.destination_id) if hour.blank? }
  before_save :contar_lista_pax, if: -> { lista_pax_alterada? && !@manter_quantidades }
  attr_writer :manter_quantidades
  # Who placed it in the order (the "Agendamentos por usuário" report); a
  # booked tour brings its booking's user (BookingItem#dados_para_ordem).
  before_create { self.usuario ||= Current.usuario }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "scancelado", "sorder_id", "vendor_id"]
  end

  def nome_forma_pagamento = FORMAS_PAGAMENTO[forma_pagamento]

  def auditoria_descricao = nome_passageiro

  # Whether it can be deleted for good (SorderItemsController#destroy), and
  # not only cancelled: nothing was received or paid on it, it didn't come
  # from a booked tour, and a SISTGER import wouldn't bring it back.
  def excluivel?
    pagamentos.none? && amountcomissionpay.to_f.zero? && amountcomissionreppay.to_f.zero? && booking_item.nil? &&
      sistger_numero.nil?
  end

  def cancelado?
    scancelado == "S"
  end

  # Passenger name is typed per item; older items pointed at a Customer.
  def nome_passageiro
    snomepax.presence || customer&.nome
  end

  # Moves the passenger to another order (SISTGER's frmTransferenciaPax).
  # Unlike SISTGER, which copied it and deleted the original, the record
  # itself moves, so its pax list, payments (with their cash entries),
  # commission bills and booked tour go along. The move is noted in its
  # comments and in both orders' history. An imported passenger loses its
  # SISTGER key, or re-importing the old order would move it back.
  def transferir_para!(destino)
    verificar_movimentacao!(destino)
    origem = sorder
    transaction do
      self.sorder = destino
      self.hour = nil if destino.destination_id != origem.destination_id # takes the new tour's pickup time
      self.sistger_numero = self.sistger_sequencial = nil
      self.comments = anotar("Transferido da OS nº #{origem.numero}")
      save!
      CashEntry.where(sorder_item_id: id).update_all(sorder_id: destino.id)
      Payable.where(sorder_item_id: id).update_all(sorder_id: destino.id)
      booking_item&.update_columns(destination_id: destino.destination_id, data_passeio: destino.data.to_date) if destino.data
    end
  rescue ActiveRecord::RecordInvalid => e
    raise NaoMovimentado, e.record.errors.full_messages.to_sentence
  end

  # Places a copy of the passenger, with its pax list, in another order:
  # same tour value and expected commissions, nothing received or paid
  # (NAO_COPIADOS). Both comments note it. Returns the copy.
  def copiar_para!(destino)
    verificar_movimentacao!(destino)
    transaction do
      copia = destino.sorder_items.new(attributes.except(*NAO_COPIADOS))
      copia.hour = nil if destino.destination_id != sorder.destination_id
      copia.comments = anotar("Copiado da OS nº #{sorder.numero}")
      companions.each { |pessoa| copia.companions.build(pessoa.attributes.slice(*%w[customer_id snome documenttype document chd colo])) }
      copia.manter_quantidades = true # the PAX/CHD typed in the original, not recounted from the list
      copia.save!
      update!(comments: anotar("Copiado para a OS nº #{destino.numero}"))
      copia
    end
  rescue ActiveRecord::RecordInvalid => e
    raise NaoMovimentado, e.record.errors.full_messages.to_sentence
  end

  # Commission still to be paid to the vendor (SISTGER's "R$ Pagar").
  def comissao_a_pagar
    amountcomission.to_f - amountcomissionpay.to_f
  end

  # Whether the commission payment screen (CommissionPaymentsController)
  # lists this passenger's vendor commission.
  def comissao_a_pagar?
    persisted? && !cancelado? && vendor.present? && !vendor.no_commission && comissao_a_pagar >= 0.01
  end

  # Commission still to be paid to the agency it was passed to.
  def comissao_repasse_a_pagar
    amountcomissionrep.to_f - amountcomissionreppay.to_f
  end

  # Tour value still to be paid by the passenger (as SISTGER: value less
  # what was paid and both discounts).
  def total_passeio
    (amount.to_f - amountpay.to_f - discount.to_f - vendor_discount.to_f).round(2)
  end

  private

  def verificar_movimentacao!(destino)
    raise NaoMovimentado, "OS de destino não encontrada." if destino.nil?
    raise NaoMovimentado, "Escolha uma OS diferente da atual." if destino.id == sorder_id
    raise NaoMovimentado, "Passageiro cancelado: reative-o antes." if cancelado?
    raise NaoMovimentado, "A OS nº #{sorder.numero} está encerrada." if sorder.encerrada?
    raise NaoMovimentado, "A OS nº #{destino.numero} está encerrada." if destino.encerrada?
  end

  # The comments plus a dated note of a transfer or copy.
  def anotar(texto)
    [comments.presence, "#{texto} em #{I18n.l(Date.current)}."].compact.join(" ")
  end

  # Both orders' history shows the move; the version of the order it left
  # moves too (after_save only moves the new one).
  def registrar_transferencia
    antes, depois = saved_change_to_sorder_id
    Sorder.nova_versao!(antes)
    [antes, depois].each do |ordem|
      SorderAuditoria.registrar!(self, "transferiu", { "sorder_id" => [antes, depois] }, sorder_id: ordem, descricao: nome_passageiro)
    end
  end

  # Cancelling and bringing back are named in the history.
  def acao_auditada
    return "alterou" unless saved_change_to_scancelado? && [scancelado_before_last_save, scancelado].include?("S")

    cancelado? ? "cancelou" : "reativou"
  end

  # A deleted passenger's history also keeps its pax list.
  def atributos_auditados_na_exclusao
    lista = companions.map(&:descricao).join("; ")
    lista.present? ? super.merge("lista_pax" => [lista, nil]) : super
  end

  # Like SISTGER's checkPax: when the pax list changes, the holder counts as
  # one PAX and each person on the list as a PAX or a CHD; colo doesn't
  # count. Items whose list isn't touched keep the typed quantities.
  def contar_lista_pax
    lista = companions.reject { |pessoa| pessoa.marked_for_destruction? || pessoa.colo? }
    self.qtdepax = 1 + lista.count { |pessoa| !pessoa.chd? }
    self.qtdechd = lista.count(&:chd?)
  end

  def lista_pax_alterada?
    companions.target.any? { |pessoa| pessoa.new_record? || pessoa.changed? || pessoa.marked_for_destruction? }
  end

  def devolver_sinais_ao_agendamento
    BookingItem.where(sorder_item_id: id).update_all(inclusao_automatica: false) # don't pull it back in by itself
    sinais = SorderItemPayment.where(sorder_item_id: id).where.not(booking_item_id: nil)
    CashEntry.where(id: sinais.select(:cash_entry_id)).update_all(sorder_id: nil, sorder_item_id: nil)
    sinais.update_all(sorder_item_id: nil)
    pagamentos.reset
  end

  # Like SISTGER's order entry: inactive vendors can't be chosen. Items
  # that already point at one (e.g. imported history) can still be edited.
  def vendedor_ativo
    errors.add(:vendor, "está inativo") if vendor && !vendor.active?
  end
end
