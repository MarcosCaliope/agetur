# A payment received from a passenger (SISTGER's tblOrdemServicoPagtos,
# "Controle de Pagamentos"). Adding or removing one moves the item's paid
# amount (amountpay) and, when asked, its cash book entry. Imported payments
# are saved without these callbacks: the import sets amountpay itself.
#
# A down payment taken on a booked tour has only booking_item; it gets the
# sorder_item when the tour is placed in an order (BookingItem#lancar_na_os!).
#
# A down payment a vendor reports on their sales screen (VendasController)
# comes with a receipt (comprovante) and stays "a conferir" (situacao
# "conferir") until the office confirms it (#confirmar!): only then does it
# move the paid amount and post to the cash book. A refused one ("recusado")
# never does. Every other payment is confirmed from the start (situacao nil).
class SorderItemPayment < ApplicationRecord
  include DaEmpresa
  da_empresa via: :sorder_item
  belongs_to :sorder_item, optional: true
  belongs_to :booking_item, optional: true
  belongs_to :cash_entry, optional: true

  has_one_attached :comprovante

  SITUACOES = { "conferir" => "A conferir", "recusado" => "Recusado" }.freeze
  COMPROVANTE_TIPOS = %w[image/png image/jpeg image/gif image/webp application/pdf].freeze
  COMPROVANTE_TAMANHO = 5.megabytes

  scope :confirmados, -> { where(situacao: nil) }
  scope :a_conferir, -> { where(situacao: "conferir") }
  scope :nao_recusados, -> { where(situacao: [nil, "conferir"]) }

  attribute :lancar_no_caixa, :boolean, default: true

  validates :data, presence: true
  validates :valor, numericality: { greater_than: 0 }
  validates :forma_pagamento, inclusion: { in: CashEntry::FORMAS.keys }, if: :lancar_no_caixa
  validate :de_um_passageiro
  validate :ordem_aberta
  validate :dentro_do_saldo, on: :create
  validates :situacao, inclusion: { in: SITUACOES.keys }, allow_nil: true
  validate :comprovante_valido

  after_create :somar_ao_pago, :lancar_caixa, if: :confirmado?
  after_destroy :tirar_do_pago, :remover_do_caixa, if: :confirmado?

  def nome_forma = CashEntry::FORMAS[forma_pagamento]

  def confirmado? = situacao.nil?
  def a_conferir? = situacao == "conferir"
  def recusado? = situacao == "recusado"
  def nome_situacao = SITUACOES.fetch(situacao, "Confirmado")

  # The office accepts a payment a vendor reported: from now on it counts as
  # paid and goes to the cash book of the day it was paid.
  def confirmar!(usuario)
    exigir_a_conferir!

    transaction do
      update!(situacao: nil, conferido_por: usuario, conferido_em: Time.current)
      somar_ao_pago
      lancar_caixa
    end
  end

  def recusar!(usuario, motivo)
    exigir_a_conferir!

    update!(situacao: "recusado", conferido_por: usuario, conferido_em: Time.current, motivo_recusa: motivo.presence)
  end

  private

  def de_um_passageiro
    errors.add(:base, "Recebimento sem passageiro.") unless sorder_item || booking_item
  end

  def ordem_aberta
    errors.add(:base, "A ordem de serviço está encerrada.") if sorder_item&.sorder&.encerrada?
  end

  def dentro_do_saldo
    return unless valor && (sorder_item || booking_item)

    saldo = sorder_item ? sorder_item.total_passeio - sorder_item.pagamentos.a_conferir.where.not(id: id).sum(:valor) : booking_item.saldo_a_informar
    errors.add(:valor, "é maior que o saldo a receber (#{format('%.2f', saldo).tr('.', ',')})") if valor > saldo.round(2)
  end

  def exigir_a_conferir!
    return if a_conferir?

    errors.add(:base, "Este recebimento não está a conferir.")
    raise ActiveRecord::RecordInvalid, self
  end

  def comprovante_valido
    return unless comprovante.attached?

    errors.add(:comprovante, "deve ser uma imagem (PNG, JPG, GIF, WebP) ou PDF") unless comprovante.content_type.in?(COMPROVANTE_TIPOS)
    errors.add(:comprovante, "deve ter no máximo 5 MB") if comprovante.byte_size > COMPROVANTE_TAMANHO
  end

  def somar_ao_pago
    return unless sorder_item

    mover_pago("recebeu", valor)
  end

  def tirar_do_pago
    return unless sorder_item

    mover_pago("estornou recebimento", -valor)
  end

  # The order's history (SorderAuditoria) gets the payment and the paid
  # amount it moved, which update_columns doesn't record.
  def mover_pago(acao, diferenca)
    antes = sorder_item.amountpay
    sorder_item.update_columns(amountpay: (antes.to_f + diferenca).round(2))
    Sorder.nova_versao!(sorder_item.sorder_id)
    SorderAuditoria.registrar!(self, acao, { "data" => [nil, data], "valor" => [nil, valor], "forma_pagamento" => [nil, nome_forma],
                                             "descricao" => [nil, descricao], "amountpay" => [antes, sorder_item.amountpay] }.reject { |_, (_, depois)| depois.blank? },
                               sorder_id: sorder_item.sorder_id, descricao: sorder_item.nome_passageiro)
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
