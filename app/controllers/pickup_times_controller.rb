# Horário de Passeios (SISTGER's frmCadHorarioPasseio): pickup time of a
# destination's tour at a hotel.
class PickupTimesController < ApplicationController
  before_action :set_pickup_time, only: %i[edit update destroy]
  before_action :set_options, only: %i[new create edit update]

  def index
    horarios = PickupTime.joins(:hotel, :destination)
    if params[:busca].present?
      termo = "%#{PickupTime.sanitize_sql_like(params[:busca].squish)}%"
      horarios = horarios.where("unaccent(hotels.sname) ILIKE unaccent(:t) OR unaccent(destinations.description) ILIKE unaccent(:t)", t: termo)
    end
    @pickup_times = horarios.includes(:hotel, :destination).order("hotels.sname", "destinations.description")
  end

  def new
    @pickup_time = PickupTime.new
  end

  def edit; end

  def create
    @pickup_time = PickupTime.new(pickup_time_params)
    if @pickup_time.save
      redirect_to pickup_times_path, notice: "Horário de passeio criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @pickup_time.update(pickup_time_params)
      redirect_to pickup_times_path, notice: "Horário de passeio atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pickup_time.destroy!
    redirect_to pickup_times_path, notice: "Horário de passeio excluído com sucesso."
  end

  private

  def set_pickup_time
    @pickup_time = PickupTime.find(params[:id])
  end

  def set_options
    @hotel_options = Hotel.order(:sname).pluck(:sname, :id)
    @destination_options = Destination.order(:description).pluck(:description, :id)
  end

  def pickup_time_params
    params.require(:pickup_time).permit(:hotel_id, :destination_id, :hora)
  end
end
