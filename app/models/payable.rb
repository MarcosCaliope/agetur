# A bill to pay ("contas a pagar"). Closing an order creates its commission
# and cost bills (Sorder#encerrar!); the rest are typed in. Paying one
# posts an exit in the cash book, and a commission payment also counts as
# paid on the passenger item.
class Payable < ApplicationRecord
  TIPOS = {
    "comissao_vendedor" => "Comissão de vendedor", "comissao_repasse" => "Comissão de repasse",
    "custo_os" => "Custo da OS", "avulsa" => "Conta avulsa"
  }.freeze

  belongs_to :credor, polymorphic: true, optional: true
  belongs_to :sorder, optional: true
  belongs_to :sorder_item, optional: true
  belongs_to :cash_entry, optional: true

  validates :tipo, inclusion: { in: TIPOS.keys }
  validates :descricao, :vencimento, presence: true
  validates :valor, numericality: { greater_than: 0 }
  validate :credor_informado

  scope :abertas, -> { where(pago_em: nil) }
  scope :pagas, -> { where.not(pago_em: nil) }

  def pago?
    pago_em.present?
  end

  def vencida?
    !pago? && vencimento < Time.zone.today
  end

  def nome_credor
    credor_nome.presence || credor.try(:sname)
  end

  def nome_tipo = TIPOS[tipo]
  def nome_forma = CashEntry::FORMAS[forma_pagamento]

  # Pays the bill: an exit in the cash book on `data`.
  def pagar!(data:, forma_pagamento:, valor: nil, usuario: nil)
    raise ActiveRecord::RecordInvalid.new(self), "Conta já paga" if pago?

    valor ||= self.valor
    transaction do
      saida = CashEntry.create!(data: data, tipo: "S", categoria: "Pagamento de conta", forma_pagamento: forma_pagamento,
                                valor: valor, descricao: "Pagamento: #{descricao}", requerente: nome_credor, usuario: usuario,
                                sorder: sorder, sorder_item: sorder_item)
      update!(pago_em: data, valor_pago: valor, forma_pagamento: forma_pagamento, cash_entry: saida)
      mover_comissao_paga(valor)
    end
  end

  # Undoes the payment and its cash book exit.
  def estornar!
    return unless pago?

    transaction do
      mover_comissao_paga(-valor_pago)
      saida = cash_entry
      update!(pago_em: nil, valor_pago: nil, forma_pagamento: nil, cash_entry: nil)
      saida&.destroy!
    end
  end

  private

  def credor_informado
    errors.add(:credor_nome, :blank) if credor_nome.blank? && credor.nil?
  end

  def mover_comissao_paga(valor)
    coluna = { "comissao_vendedor" => :amountcomissionpay, "comissao_repasse" => :amountcomissionreppay }[tipo]
    return unless coluna && sorder_item

    sorder_item.update_columns(coluna => (sorder_item[coluna].to_f + valor).round(2))
  end
end
