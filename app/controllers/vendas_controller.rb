# Vendas: a vendor's own screen (a User linked to a Vendor, User#vendedor?).
# They sell tours as Agendamentos (Booking) under their own name, which
# Sorder#incluir_agendamentos! then pulls into the orders, and report what
# the customer paid, with a receipt (PagamentoInformado). Those payments wait
# for the office (ConferenciaSinaisController) before counting as paid.
#
# Open only to vendor logins, so it's left out of the route permissions
# (Permissao::LIVRES); a vendor login opens nothing else.
class VendasController < ApplicationController
  skip_before_action :verificar_permissao!
  before_action :exigir_vendedor
  before_action :set_booking, only: %i[show pagamento]
  before_action :set_options, only: %i[new create]

  def index
    @bookings = minhas.includes(items: %i[destination pagamentos sorder_item]).order(data: :desc, id: :desc).limit(100)
  end

  def show
    @pagamento = PagamentoInformado.new(booking: @booking, forma_pagamento: "O")
  end

  def new
    @booking = Booking.new
    @booking.items.build(data_passeio: Time.zone.tomorrow)
    @pagamento = PagamentoInformado.new(forma_pagamento: "O")
  end

  # The booking and its first payment are saved together, or neither.
  def create
    @booking = Booking.new(booking_params.merge(vendor: @vendedor, data: Time.zone.today, usuario: usuario_atual))
    @pagamento = PagamentoInformado.new(pagamento_params.merge(booking: @booking, usuario: usuario_atual))
    salvo = false
    Booking.transaction do
      salvo = @booking.save && (@pagamento.vazio? || @pagamento.salvar)
      raise ActiveRecord::Rollback unless salvo
    end
    if salvo
      redirect_to venda_path(@booking), notice: "Venda registrada. O pagamento informado aguarda a conferência do escritório."
    else
      @booking.items.build(data_passeio: Time.zone.tomorrow) if @booking.items.empty?
      render :new, status: :unprocessable_entity
    end
  end

  # POST /vendas/1/pagamento: another (or the rest of the) payment.
  def pagamento
    @pagamento = PagamentoInformado.new(pagamento_params.merge(booking: @booking, usuario: usuario_atual))
    if @pagamento.salvar
      redirect_to venda_path(@booking), notice: "Pagamento informado. Ele aguarda a conferência do escritório."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def exigir_vendedor
    if !user_signed_in? || !current_user.vendedor?
      redirect_to root_path, alert: "Esta página é só para vendedores."
    elsif !(@vendedor = current_user.vendor)&.active?
      redirect_to root_path, alert: "Seu cadastro de vendedor está inativo. Fale com o escritório."
    end
  end

  def minhas
    Booking.where(vendor_id: @vendedor.id)
  end

  def set_booking
    @booking = minhas.find(params[:id])
  end

  def set_options
    @hotel_options = Hotel.order(:sname).pluck(:sname, :id)
    @destination_options = Destination.order(:description).map do |destino|
      preco = ActiveSupport::NumberHelper.number_to_currency(destino.valuenormal.to_f)
      ["#{destino.description} (#{preco} adulto)", destino.id]
    end
  end

  def booking_params
    params.require(:booking).permit(:snome, :telefone, :hotel_id, :apto, :documenttype, :document, :observacoes,
                                    companions_attributes: %i[id snome documenttype document chd colo _destroy],
                                    items_attributes: %i[destination_id data_passeio qtdepax qtdechd valor observacao])
  end

  def pagamento_params
    params.fetch(:pagamento_informado, {}).permit(:valor, :forma_pagamento, :comprovante)
  end
end
