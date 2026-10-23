# A payment a vendor reports on their sales screen (VendasController), with
# an optional receipt image: split over the booking's active tours, in date
# order, each getting what's still to receive, as SorderItemPayments "a
# conferir" that the office confirms or refuses (ConferenciaSinaisController).
# A tour already in an order takes it on the order's passenger too, so
# confirming it moves the passenger's paid amount.
class PagamentoInformado
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :valor, :decimal
  attribute :forma_pagamento, :string
  attr_accessor :booking, :comprovante, :usuario

  validates :valor, numericality: { greater_than: 0 }
  validates :forma_pagamento, inclusion: { in: CashEntry::FORMAS.keys }
  validate :dentro_do_saldo
  validate :comprovante_valido

  # The form leaves both blank when nothing was paid.
  def vazio? = valor.blank? && comprovante.blank?

  # What the vendor may still report: active tours not in a closed order,
  # less what's paid or waiting to be checked.
  def saldo
    passeios.sum { |passeio, a_receber| a_receber }
  end

  def salvar
    return false unless valid?

    blob = anexo
    restante = valor.round(2)
    SorderItemPayment.transaction do
      passeios.each do |passeio, a_receber|
        break unless restante.positive?

        parte = [restante, a_receber].min
        next unless parte.positive?

        pagamento = SorderItemPayment.new(booking_item: passeio, sorder_item: passeio.sorder_item, data: Time.zone.today, valor: parte,
                                          forma_pagamento: forma_pagamento, situacao: "conferir", usuario: usuario,
                                          descricao: "Informado pelo vendedor #{booking.vendor.sname}")
        pagamento.comprovante.attach(blob) if blob
        pagamento.save!
        restante -= parte
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.record.errors.full_messages.to_sentence)
    false
  end

  private

  def passeios
    @passeios ||= booking.items.ativos.includes(:pagamentos, sorder_item: %i[sorder pagamentos]).reject { |passeio| passeio.sorder_item&.sorder&.encerrada? }
                         .map { |passeio| [passeio, a_receber(passeio).round(2)] }
  end

  def a_receber(passeio)
    if passeio.lancado?
      passeio.sorder_item.total_passeio.to_d - passeio.sorder_item.pagamentos.select(&:a_conferir?).sum(&:valor)
    else
      passeio.saldo_a_informar
    end
  end

  def anexo
    return if comprovante.blank?

    ActiveStorage::Blob.create_and_upload!(io: comprovante, filename: comprovante.original_filename, content_type: comprovante.content_type)
  end

  def dentro_do_saldo
    return unless valor.to_d.positive? && booking

    errors.add(:valor, "é maior que o saldo a receber (#{format('%.2f', saldo).tr('.', ',')})") if valor.round(2) > saldo
  end

  def comprovante_valido
    return if comprovante.blank?

    unless comprovante.content_type.in?(SorderItemPayment::COMPROVANTE_TIPOS)
      errors.add(:comprovante, "deve ser uma imagem (PNG, JPG, GIF, WebP) ou PDF")
    end
    errors.add(:comprovante, "deve ter no máximo 5 MB") if comprovante.size > SorderItemPayment::COMPROVANTE_TAMANHO
  end
end
