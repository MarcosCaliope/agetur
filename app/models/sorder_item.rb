class SorderItem < ApplicationRecord
  belongs_to :sorder
  belongs_to :customer, optional: true
  belongs_to :hotel, optional: true
  belongs_to :vendor, optional: true

  # scancelado is "S"/"N"; items saved before the column existed are blank
  # and count as not cancelled.
  scope :ativos, -> { where(scancelado: [nil, "", "N"]) }

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

  # Tour value still to be paid by the passenger.
  def total_passeio
    amount.to_f - amountpay.to_f
  end
end
