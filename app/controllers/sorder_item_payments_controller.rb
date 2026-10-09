# Payments received from a passenger (SISTGER's "Controle de Pagamentos").
class SorderItemPaymentsController < ApplicationController
  before_action :set_sorder_item

  # GET /sorder_items/1/recebimentos
  def index
    @pagamento = @sorder_item.pagamentos.build(data: Time.zone.today, forma_pagamento: "D", valor: saldo_sugerido)
  end

  # POST /sorder_items/1/recebimentos
  def create
    @pagamento = @sorder_item.pagamentos.build(pagamento_params.merge(usuario: usuario_atual))
    if @pagamento.save
      redirect_to sorder_item_recebimentos_path(@sorder_item), notice: "Recebimento lançado com sucesso."
    else
      render :index, status: :unprocessable_entity
    end
  end

  # DELETE /sorder_items/1/recebimentos/2
  def destroy
    pagamento = @sorder_item.pagamentos.find(params[:id])
    if @sorder_item.sorder.encerrada?
      redirect_to sorder_item_recebimentos_path(@sorder_item), alert: "Ordem de serviço encerrada: reabra para excluir recebimentos."
    else
      pagamento.destroy!
      redirect_to sorder_item_recebimentos_path(@sorder_item), notice: "Recebimento excluído com sucesso."
    end
  end

  private

  def set_sorder_item
    @sorder_item = SorderItem.includes(:sorder).find(params[:sorder_item_id])
  end

  def saldo_sugerido
    [@sorder_item.total_passeio, 0].max
  end

  def pagamento_params
    params.require(:sorder_item_payment).permit(:data, :valor, :descricao, :forma_pagamento, :lancar_no_caixa)
  end
end
