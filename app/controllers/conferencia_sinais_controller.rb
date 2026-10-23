# Sinais a conferir: payments vendors reported on their sales screen
# (PagamentoInformado), with their receipts. Confirming one makes it paid and
# posts it to the cash book (SorderItemPayment#confirmar!); refusing one
# keeps it, marked, for the vendor to see.
class ConferenciaSinaisController < ApplicationController
  before_action :set_pagamento, only: %i[confirmar recusar]

  # GET /agendamentos/sinais-a-conferir
  def index
    @pagamentos = SorderItemPayment.a_conferir.includes(:sorder_item, comprovante_attachment: :blob,
                                                        booking_item: [:destination, { booking: :vendor }])
                                   .order(:data, :id)
    @recentes = SorderItemPayment.where.not(conferido_em: nil).includes(booking_item: [:destination, { booking: :vendor }])
                                 .order(conferido_em: :desc).limit(20)
  end

  def confirmar
    @pagamento.confirmar!(usuario_atual)
    redirect_to conferencia_sinais_path, notice: "Recebimento confirmado e lançado no caixa."
  rescue ActiveRecord::RecordInvalid
    redirect_to conferencia_sinais_path, alert: @pagamento.errors.full_messages.to_sentence
  end

  def recusar
    @pagamento.recusar!(usuario_atual, params[:motivo_recusa])
    redirect_to conferencia_sinais_path, notice: "Recebimento recusado."
  rescue ActiveRecord::RecordInvalid
    redirect_to conferencia_sinais_path, alert: @pagamento.errors.full_messages.to_sentence
  end

  private

  def set_pagamento
    @pagamento = SorderItemPayment.find(params[:id])
  end
end
