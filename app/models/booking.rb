# A customer's booking of tours (SISTGER's "Lança Agendamentos",
# tblAgendamentos): who, where they stay, the vendor who sold it, the pax
# list and the tours (BookingItem), each later placed in a service order.
class Booking < ApplicationRecord
  include DaEmpresa
  belongs_to :customer, optional: true
  belongs_to :hotel, optional: true
  belongs_to :vendor
  has_many :items, -> { order(:data_passeio, :id) }, class_name: "BookingItem", inverse_of: :booking, dependent: :destroy
  has_many :companions, -> { order(:id) }, class_name: "BookingCompanion", inverse_of: :booking, dependent: :delete_all
  accepts_nested_attributes_for :companions, reject_if: ->(atributos) { atributos["snome"].blank? }, allow_destroy: true
  # The vendor's sales form (VendasController) takes the tours with the booking.
  accepts_nested_attributes_for :items, reject_if: ->(atributos) { atributos["destination_id"].blank? }

  # "Deseja incluir este PAX no Cad. de Clientes?"
  attribute :cadastrar_cliente, :boolean, default: false

  validates :data, :snome, presence: true
  validates :forma_pagamento, inclusion: { in: CashEntry::FORMAS.keys }, allow_blank: true
  validates :parcelas, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :vendedor_ativo, if: -> { vendor_id.present? && vendor_id_changed? }

  before_save :cadastrar_cliente!, if: -> { cadastrar_cliente && customer.nil? }
  before_destroy :exigir_nada_lancado, prepend: true

  def total
    items.ativos.sum(:valor)
  end

  def pago
    SorderItemPayment.confirmados.where(booking_item_id: items.ativos.select(:id)).sum(:valor)
  end

  # The holder plus the pax list, counted like an order item's list
  # (SorderItem#contar_lista_pax): colo counts as neither PAX nor CHD.
  def pax_sugerido = 1 + companions.count { |pessoa| !pessoa.chd? && !pessoa.colo? }
  def chd_sugerido = companions.count { |pessoa| pessoa.chd? && !pessoa.colo? }

  private

  def vendedor_ativo
    errors.add(:vendor, "está inativo") if vendor && !vendor.active?
  end

  def cadastrar_cliente!
    self.customer = Customer.create!(nome: snome, phone: telefone, document: (document if documenttype == "CPF"))
  end

  def exigir_nada_lancado
    return unless items.where.not(sorder_item_id: nil).exists?

    errors.add(:base, "Há passeios deste agendamento lançados em ordem de serviço: retire-os da OS antes de excluir.")
    throw :abort
  end
end
