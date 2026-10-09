# A booked tour (SISTGER's tblAgendamentosItens). Placing it in an order
# (#lancar_na_os!) creates the order's passenger item, copies the pax list,
# fills the vendor commission and moves the down payments over.
class BookingItem < ApplicationRecord
  class NaoLancado < StandardError; end

  belongs_to :booking
  belongs_to :destination
  belongs_to :sorder_item, optional: true
  has_many :pagamentos, -> { order(:data, :id) }, class_name: "SorderItemPayment", dependent: :destroy

  scope :ativos, -> { where(cancelado: false) }
  scope :pendentes, -> { ativos.where(sorder_item_id: nil) }

  validates :data_passeio, presence: true
  validates :qtdepax, :qtdechd, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :valor, numericality: { greater_than_or_equal_to: 0 }

  before_validation :sugerir_hora_e_valor
  before_destroy :exigir_nao_lancado, prepend: true

  def lancado?
    sorder_item_id.present?
  end

  # Saved payments only: a payment being validated is already in the association.
  def pago
    pagamentos.select(&:persisted?).sum(&:valor)
  end

  def saldo
    valor.to_d - pago
  end

  # Open orders of the same destination on the tour's date.
  def ordens_candidatas
    Sorder.where(destination_id: destination_id, encerrada: false, data: data_passeio.all_day).order(:id)
  end

  def lancar_na_os!(sorder)
    raise NaoLancado, "Passeio cancelado." if cancelado?
    raise NaoLancado, "Passeio já lançado na OS nº #{sorder_item.sorder_id}." if lancado?
    raise NaoLancado, "A OS nº #{sorder.id} está encerrada." if sorder.encerrada?
    raise NaoLancado, "A OS nº #{sorder.id} é de outro roteiro." if sorder.destination_id != destination_id

    transaction do
      b = booking
      item = sorder.sorder_items.create!(
        snomepax: b.snome, customer: b.customer, documenttype: b.documenttype, document: b.document, hotel: b.hotel,
        apto: b.apto, phone: b.telefone, vendor: b.vendor, qtdepax: qtdepax, qtdechd: qtdechd, hour: hora, amount: valor,
        amountcomission: comissao_prevista, comments: observacao, scancelado: "N"
      )
      b.companions.each { |pessoa| item.companions.create!(pessoa.atributos_para_ordem) }
      CashEntry.where(id: pagamentos.select(:cash_entry_id)).update_all(sorder_id: sorder.id, sorder_item_id: item.id)
      pagamentos.update_all(sorder_item_id: item.id)
      item.update_columns(amountpay: pagamentos.sum(:valor).to_f)
      update!(sorder_item: item)
      item
    end
  rescue ActiveRecord::RecordInvalid => e
    raise NaoLancado, e.record.errors.full_messages.to_sentence
  end

  # Takes it back out of the order; its down payments stay with the booking.
  def retirar_da_os!
    raise NaoLancado, "Passeio não está em ordem de serviço." unless lancado?
    raise NaoLancado, "A OS nº #{sorder_item.sorder_id} está encerrada." if sorder_item.sorder.encerrada?

    transaction do
      item = sorder_item
      update!(sorder_item: nil)
      item.destroy! # SorderItem hands the down payments back first
    end
  end

  # Vendor commission for this tour: the vendor's % for the destination
  # (Comissão por roteiro), else their default %.
  def comissao_prevista
    vendedor = booking.vendor
    return 0 if vendedor.nil? || vendedor.no_commission

    pct = VendorDestination.find_by(vendor_id: vendedor.id, destination_id: destination_id)&.commission || vendedor.commission
    (valor.to_d * pct.to_d / 100).round(2).to_f
  end

  private

  # SISTGER suggests the pickup time (hotel × destination) and the price
  # (adult price × pax + child price × chd; half the adult price without one).
  def sugerir_hora_e_valor
    return unless destination

    self.hora = PickupTime.hora_para(booking&.hotel_id, destination_id) if hora.blank?
    return unless valor.to_d.zero?

    adulto = destination.valuenormal.to_d
    crianca = destination.valuenormalchd.presence&.to_d || adulto / 2
    self.valor = (adulto * qtdepax.to_i + crianca * qtdechd.to_i).round(2)
  end

  def exigir_nao_lancado
    return unless lancado?

    errors.add(:base, "Passeio lançado na OS nº #{sorder_item.sorder_id}: retire-o da OS antes de excluir.")
    throw :abort
  end
end
