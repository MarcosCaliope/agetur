# Agendamentos (SISTGER's "Lança Agendamentos"): a customer's booking with
# its pax list and tours. The list is SISTGER's "Relação de Agendamento de
# Passeios", one row per tour.
class BookingsController < ApplicationController
  before_action :set_booking, only: %i[show edit update destroy]
  before_action :set_options, only: %i[new create edit update]

  # GET /agendamentos?inicio=&fim=&situacao=&busca=
  def index
    @inicio = data_param(:inicio) || Time.zone.today
    @fim = data_param(:fim) || @inicio + 30
    @situacao = %w[pendentes lancados cancelados todos].include?(params[:situacao]) ? params[:situacao] : "todos"

    passeios = BookingItem.joins(:booking, :destination).where(data_passeio: @inicio..@fim)
    passeios = case @situacao
               when "pendentes" then passeios.pendentes
               when "lancados" then passeios.ativos.where.not(sorder_item_id: nil)
               when "cancelados" then passeios.where(cancelado: true)
               else passeios
               end
    if params[:busca].present?
      termo = "%#{BookingItem.sanitize_sql_like(params[:busca].squish)}%"
      passeios = passeios.left_joins(booking: %i[hotel vendor]).where(
        "unaccent(bookings.snome) ILIKE unaccent(:t) OR unaccent(destinations.description) ILIKE unaccent(:t) OR " \
        "unaccent(hotels.sname) ILIKE unaccent(:t) OR unaccent(vendors.sname) ILIKE unaccent(:t)", t: termo
      )
    end
    @passeios = passeios.includes(:destination, :pagamentos, :sorder_item, booking: %i[hotel vendor]).order(:data_passeio, :hora, :id)

    # The list is by tour, so bookings with none yet are shown apart.
    sem_passeio = Booking.where.missing(:items).includes(:hotel, :vendor).order(:data, :id)
    if params[:busca].present?
      sem_passeio = sem_passeio.left_joins(:hotel, :vendor).where(
        "unaccent(bookings.snome) ILIKE unaccent(:t) OR unaccent(hotels.sname) ILIKE unaccent(:t) OR unaccent(vendors.sname) ILIKE unaccent(:t)",
        t: "%#{Booking.sanitize_sql_like(params[:busca].squish)}%"
      )
    end
    @sem_passeio = sem_passeio
  end

  # GET /agendamentos/pendentes: tours not in an order yet, by date and destination.
  def pendentes
    @grupos = BookingItem.pendentes.where(data_passeio: (data_param(:inicio) || Time.zone.today)..)
                         .includes(:destination, :pagamentos, booking: :hotel).order(:data_passeio, :destination_id, :hora)
                         .group_by { |passeio| [passeio.data_passeio, passeio.destination] }
    datas = @grupos.keys.map(&:first)
    @ordens = if datas.empty?
                {}
              else
                Sorder.where(encerrada: false, destination_id: @grupos.keys.map { |_, destino| destino.id },
                             data: datas.min.beginning_of_day..datas.max.end_of_day)
                      .order(:id).group_by { |ordem| [ordem.data.to_date, ordem.destination_id] }
              end
  end

  def show
    @passeio = @booking.items.build(data_passeio: Time.zone.today, qtdepax: @booking.pax_sugerido, qtdechd: @booking.chd_sugerido)
    @booking.items.reset
    @destination_options = Destination.order(:description).pluck(:description, :id)
  end

  def new
    @booking = Booking.new(data: Time.zone.today, forma_pagamento: "D")
  end

  def edit; end

  def create
    @booking = Booking.new(booking_params.merge(usuario: usuario_atual))
    if @booking.save
      redirect_to @booking, notice: "Agendamento criado. Inclua os passeios."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @booking.update(booking_params)
      redirect_to @booking, notice: "Agendamento atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @booking.destroy
      redirect_to bookings_path, notice: "Agendamento excluído com sucesso."
    else
      redirect_to @booking, alert: @booking.errors.full_messages.to_sentence
    end
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def set_options
    @customer_options = Customer.order(:nome).pluck(:nome, :id)
    @hotel_options = Hotel.order(:sname).pluck(:sname, :id)
    @vendor_options = Vendor.ativos.or(Vendor.where(id: @booking&.vendor_id)).order(:sname).pluck(:sname, :id)
  end

  def data_param(nome)
    Date.iso8601(params[nome]) if params[nome].present?
  rescue Date::Error
    nil
  end

  def booking_params
    params.require(:booking).permit(:data, :snome, :customer_id, :cadastrar_cliente, :telefone, :hotel_id, :apto, :documenttype,
                                    :document, :vendor_id, :forma_pagamento, :parcelas, :observacoes,
                                    companions_attributes: %i[id snome documenttype document chd colo _destroy])
  end
end
