# Down payments of a booked tour. Once the tour is in an order, payments
# are taken on the order's passenger (SorderItemPaymentsController).
class BookingItemPaymentsController < ApplicationController
  before_action :set_item

  def index
    return redirect_to(sorder_item_recebimentos_path(@item.sorder_item)) if @item.lancado?

    @pagamento = SorderItemPayment.new(booking_item: @item, data: Time.zone.today, forma_pagamento: @item.booking.forma_pagamento.presence || "D",
                                        valor: [@item.saldo, 0].max)
  end

  def create
    @pagamento = SorderItemPayment.new(booking_item: @item, **params.require(:sorder_item_payment).permit(:data, :valor, :descricao, :forma_pagamento,
                                                                                    :lancar_no_caixa).to_h.symbolize_keys,
                                       usuario: usuario_atual)
    if @pagamento.save
      redirect_to booking_item_recebimentos_path(@item.booking, @item), notice: "Sinal lançado com sucesso."
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @item.pagamentos.find(params[:id]).destroy!
    redirect_to booking_item_recebimentos_path(@item.booking, @item), notice: "Sinal excluído com sucesso."
  end

  private

  def set_item
    @item = BookingItem.where(booking_id: params[:booking_id]).find(params[:item_id])
  end
end
