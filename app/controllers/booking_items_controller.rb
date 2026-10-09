# The tours of a booking, and placing them in (or taking them out of) a
# service order.
class BookingItemsController < ApplicationController
  before_action :set_booking
  before_action :set_item, except: :create

  def create
    @item = @booking.items.build(item_params)
    if @item.save
      redirect_to @booking, notice: aviso_ordem(@item, "Passeio incluído.")
    else
      redirect_to @booking, alert: "Passeio não incluído: #{@item.errors.full_messages.to_sentence}"
    end
  end

  def edit
    @destination_options = Destination.order(:description).pluck(:description, :id)
  end

  def update
    atributos = @item.lancado? ? item_params.slice(:observacao) : item_params
    if @item.update(atributos)
      redirect_to @booking, notice: aviso_ordem(@item, "Passeio atualizado.")
    else
      @destination_options = Destination.order(:description).pluck(:description, :id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @item.destroy
      redirect_to @booking, notice: "Passeio excluído."
    else
      redirect_to @booking, alert: @item.errors.full_messages.to_sentence
    end
  end

  # PATCH /agendamentos/1/passeios/2/lancar?sorder_id=3
  def lancar
    ordem = Sorder.find(params[:sorder_id])
    @item.lancar_na_os!(ordem)
    redirect_back fallback_location: @booking, notice: "Passeio lançado na OS nº #{ordem.id}."
  rescue BookingItem::NaoLancado => e
    redirect_back fallback_location: @booking, alert: "Não foi possível lançar: #{e.message}"
  end

  # PATCH /agendamentos/1/passeios/2/retirar
  def retirar
    @item.retirar_da_os!
    redirect_to @booking, notice: "Passeio retirado da OS. Os sinais voltaram para o agendamento."
  rescue BookingItem::NaoLancado => e
    redirect_to @booking, alert: e.message
  end

  private

  def set_booking
    @booking = Booking.find(params[:booking_id])
  end

  def set_item
    @item = @booking.items.find(params[:id])
  end

  def item_params
    params.require(:booking_item).permit(:destination_id, :data_passeio, :hora, :qtdepax, :qtdechd, :valor, :cancelado, :observacao)
  end

  # Like SISTGER, point out an order already set up for the tour.
  def aviso_ordem(item, texto)
    return texto if item.lancado? || item.cancelado?

    ordens = item.ordens_candidatas.pluck(:id)
    ordens.any? ? "#{texto} Já existe OS do roteiro nesta data (nº #{ordens.join(', ')}): use \"Lançar na OS\"." : texto
  end
end
