class SorderItem < ApplicationRecord
  belongs_to :sorder
  belongs_to :customer, optional: true
  belongs_to :hotel, optional: true
  belongs_to :vendor, optional: true
  belongs_to :agency, optional: true
  has_many :pagamentos, -> { order(:data, :id) }, class_name: "SorderItemPayment", dependent: :destroy
  has_many :companions, -> { order(:sistger_seq_adicional, :id) }, class_name: "SorderItemCompanion", inverse_of: :sorder_item,
                        dependent: :delete_all
  accepts_nested_attributes_for :companions, reject_if: ->(atributos) { atributos["snome"].blank? }, allow_destroy: true

  # scancelado is "S"/"N"; items saved before the column existed are blank
  # and count as not cancelled.
  scope :ativos, -> { where(scancelado: [nil, "", "N"]) }

  validate :vendedor_ativo, if: -> { vendor_id.present? && vendor_id_changed? }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "scancelado", "sorder_id", "vendor_id"]
  end

  def cancelado?
    scancelado == "S"
  end

  # Passenger name is typed per item; older items pointed at a Customer.
  def nome_passageiro
    snomepax.presence || customer&.nome
  end

  # Commission still to be received from the vendor.
  def total_receber
    amountcomission.to_f - amountcomissionpay.to_f
  end

  # Tour value still to be paid by the passenger (as SISTGER: value less
  # what was paid and both discounts).
  def total_passeio
    (amount.to_f - amountpay.to_f - discount.to_f - vendor_discount.to_f).round(2)
  end

  private

  # Like SISTGER's order entry: inactive vendors can't be chosen. Items
  # that already point at one (e.g. imported history) can still be edited.
  def vendedor_ativo
    errors.add(:vendor, "está inativo") if vendor && !vendor.active?
  end
end
