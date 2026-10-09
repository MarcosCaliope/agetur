# A bill to pay ("contas a pagar"). Closing an order creates its commission
# and cost bills (Sorder#encerrar!); the rest are typed in. Paying one
# posts an exit in the cash book, and a commission payment also counts as
# paid on the passenger item.
class Payable < ApplicationRecord
  TIPOS = {
    "comissao_vendedor" => "Comissão de vendedor", "comissao_repasse" => "Comissão de repasse",
    "custo_os" => "Custo da OS", "avulsa" => "Conta avulsa"
  }.freeze

  # Commission bills and the origem that ties them to the passenger.
  COMISSOES = { "comissao_vendedor" => "vendedor", "comissao_repasse" => "repasse" }.freeze

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

  # The open bill for what's left of a passenger's commission, or nil when
  # nothing is (or the vendor isn't paid commission): the existing open one
  # with its value brought up to date, else a new one.
  def self.de_comissao(item, tipo, vencimento:)
    vendedor = tipo == "comissao_vendedor"
    credor = vendedor ? item.vendor : item.agency
    saldo = (vendedor ? item.comissao_a_pagar : item.comissao_repasse_a_pagar).round(2)
    return if credor.nil? || (vendedor && credor.no_commission) || !saldo.positive?

    conta = abertas.find_or_initialize_by(sorder_item_id: item.id, origem: COMISSOES.fetch(tipo))
    conta.assign_attributes(tipo: tipo, credor: credor, sorder_id: item.sorder_id, valor: saldo,
                            descricao: "#{vendedor ? 'Comissão' : 'Comissão de repasse'} OS #{item.sorder_id} PAX #{item.nome_passageiro}")
    conta.vencimento ||= vencimento
    conta
  end

  # Pays several bills on `data` with one cash exit per creditor (SISTGER's
  # "Pagamento de Comissões"). Returns the exits.
  def self.pagar_em_lote!(contas, data:, forma_pagamento:, usuario: nil)
    transaction do
      contas.group_by { |conta| [conta.credor_type, conta.credor_id, conta.nome_credor] }.map do |(_, _, nome), grupo|
        ordens = grupo.filter_map(&:sorder_id).uniq.sort
        saida = CashEntry.create!(
          data: data, tipo: "S", categoria: "Pagamento de conta", forma_pagamento: forma_pagamento, valor: grupo.sum(&:valor),
          descricao: "Pagamento de comissões a #{nome}: #{grupo.size} passageiro(s)#{" - OS #{ordens.join(', ')}" if ordens.any?}",
          requerente: nome, usuario: usuario
        )
        grupo.each { |conta| conta.send(:registrar_pagamento!, data, forma_pagamento, conta.valor, saida) }
        saida
      end
    end
  end

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
      registrar_pagamento!(data, forma_pagamento, valor, saida)
    end
  end

  # Undoes the payment and its cash book exit. A batch exit is undone whole:
  # every bill paid in it goes back to open.
  def estornar!
    return unless pago?

    transaction do
      saida = cash_entry
      (saida ? saida.payables.to_a : [self]).each do |conta|
        conta.mover_comissao_paga(-conta.valor_pago)
        conta.update!(pago_em: nil, valor_pago: nil, forma_pagamento: nil, cash_entry: nil)
      end
      saida&.reload&.destroy!
    end
  end

  # Also paid in this bill's cash exit (a batch payment).
  def lote
    cash_entry ? cash_entry.payables.where.not(id: id) : Payable.none
  end

  protected

  def mover_comissao_paga(valor)
    coluna = { "comissao_vendedor" => :amountcomissionpay, "comissao_repasse" => :amountcomissionreppay }[tipo]
    return unless coluna && sorder_item

    sorder_item.update_columns(coluna => (sorder_item[coluna].to_f + valor).round(2))
  end

  private

  def registrar_pagamento!(data, forma_pagamento, valor, saida)
    update!(pago_em: data, valor_pago: valor, forma_pagamento: forma_pagamento, cash_entry: saida)
    mover_comissao_paga(valor)
  end

  def credor_informado
    errors.add(:credor_nome, :blank) if credor_nome.blank? && credor.nil?
  end
end
