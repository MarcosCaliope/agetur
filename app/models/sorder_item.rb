class SorderItem < ApplicationRecord
  include DaEmpresa
  da_empresa via: :sorder
  include Auditavel
  belongs_to :sorder
  # Any change to a passenger moves the order's version (Sorder.nova_versao!).
  after_save { Sorder.nova_versao!(sorder_id) }
  after_destroy { Sorder.nova_versao!(sorder_id) }
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

  # scancelado is "S"/"N"; items saved before the column existed are blank
  # and count as not cancelled.
  scope :ativos, -> { where(scancelado: [nil, "", "N"]) }

  validates :forma_pagamento, inclusion: { in: FORMAS_PAGAMENTO.keys }, allow_blank: true
  validate :vendedor_ativo, if: -> { vendor_id.present? && vendor_id_changed? }

  # Like SISTGER: a blank time takes the tour's pickup time at the hotel.
  before_validation { self.hour = PickupTime.hora_para(hotel_id, sorder&.destination_id) if hour.blank? }
  before_save :contar_lista_pax, if: :lista_pax_alterada?
  # Who placed it in the order (the "Agendamentos por usuário" report); a
  # booked tour brings its booking's user (BookingItem#dados_para_ordem).
  before_create { self.usuario ||= Current.usuario }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "scancelado", "sorder_id", "vendor_id"]
  end

  def nome_forma_pagamento = FORMAS_PAGAMENTO[forma_pagamento]

  def auditoria_descricao = nome_passageiro

  def cancelado?
    scancelado == "S"
  end

  # Passenger name is typed per item; older items pointed at a Customer.
  def nome_passageiro
    snomepax.presence || customer&.nome
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
