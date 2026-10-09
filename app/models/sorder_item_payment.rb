# A payment received from a passenger (SISTGER's tblOrdemServicoPagtos,
# "Controle de Pagamentos"). Adding or removing one moves the item's paid
# amount (amountpay) and, when asked, its cash book entry. Imported payments
# are saved without these callbacks: the import sets amountpay itself.
#
# A down payment taken on a booked tour has only booking_item; it gets the
# sorder_item when the tour is placed in an order (BookingItem#lancar_na_os!).
class SorderItemPayment < ApplicationRecord
  belongs_to :sorder_item, optional: true
  belongs_to :booking_item, optional: true
  belongs_to :cash_entry, optional: true

  attribute :lancar_no_caixa, :boolean, default: true

  validates :data, presence: true
  validates :valor, numericality: { greater_than: 0 }
  validates :forma_pagamento, inclusion: { in: CashEntry::FORMAS.keys }, if: :lancar_no_caixa
  validate :de_um_passageiro
  validate :ordem_aberta
  validate :dentro_do_saldo, on: :create

  after_create :somar_ao_pago, :lancar_caixa
  after_destroy :tirar_do_pago, :remover_do_caixa

  def nome_forma = CashEntry::FORMAS[forma_pagamento]

  private

  def de_um_passageiro
    errors.add(:base, "Recebimento sem passageiro.") unless sorder_item || booking_item
  end

  def ordem_aberta
    errors.add(:base, "A ordem de serviço está encerrada.") if sorder_item&.sorder&.encerrada?
  end

  def dentro_do_saldo
    return unless valor && (sorder_item || booking_item)

    saldo = sorder_item ? sorder_item.total_passeio : booking_item.saldo
    errors.add(:valor, "é maior que o saldo a receber (#{format('%.2f', saldo).tr('.', ',')})") if valor > saldo.round(2)
  end

  def somar_ao_pago
    return unless sorder_item

    sorder_item.update_columns(amountpay: (sorder_item.amountpay.to_f + valor).round(2))
  end

  def tirar_do_pago
    return unless sorder_item

    sorder_item.update_columns(amountpay: (sorder_item.amountpay.to_f - valor).round(2))
  end

  def lancar_caixa
    return unless lancar_no_caixa

    item = sorder_item
    origem, pax = if item
                    ["Recebimento do passeio OS: #{item.sorder_id}", item.nome_passageiro]
                  else
                    ["Sinal do agendamento nº #{booking_item.booking_id} (#{booking_item.destination.description})", booking_item.booking.snome]
                  end
    entrada = CashEntry.create!(
      data: data, tipo: "E", categoria: "Recebimento de passeio", forma_pagamento: forma_pagamento, valor: valor,
      descricao: ["#{origem} PAX: #{pax}", descricao.presence].compact.join(" - "),
      requerente: pax, usuario: usuario, sorder_id: item&.sorder_id, sorder_item: item
    )
    update_column(:cash_entry_id, entrada.id)
  end

  def remover_do_caixa
    cash_entry&.destroy!
  end
end
