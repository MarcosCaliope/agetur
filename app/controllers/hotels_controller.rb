class HotelsController < ApplicationController
  before_action :set_hotel, only: [:show, :edit, :update, :destroy, :export]
  before_action :set_state_options, only: [:new, :create, :edit, :update]

  # GET /hotels
  # GET /hotels.json
  def index
    @hotels = Hotel.pesquisar(params[:busca]).includes(:state).order(:id)
    respond_to do |format|
      format.html
      format.pdf do
        #pdf = Prawn::Document.new
        pdf = HotelPdf.new (@hotels)
        #pdf.text "Hello"
        send_data pdf.render, filename: 'hotels.pdf', type: 'application/pdf', disposition: "inline"
      end
    end
  end

  # GET /hotels/1
  # GET /hotels/1.json
  def show
  end

  # GET /hotels/new
  def new
    @hotel = Hotel.new
  end

  # GET /hotels/1/edit
  def edit
  end

  # POST /hotels
  # POST /hotels.json
  def create
    @hotel = Hotel.new(hotel_params)

    respond_to do |format|
      if @hotel.save
        format.html { redirect_to @hotel, notice: 'Hotel criado com sucesso.' }
        format.json { render :show, status: :created, location: @hotel }
      else
        format.html { render :new }
        format.json { render json: @hotel.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hotels/1
  # PATCH/PUT /hotels/1.json
  def update
    respond_to do |format|
      if @hotel.update(hotel_params)
        format.html { redirect_to @hotel, notice: 'Hotel atualizado com sucesso.' }
        format.json { render :show, status: :ok, location: @hotel }
      else
        format.html { render :edit }
        format.json { render json: @hotel.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotels/1
  # DELETE /hotels/1.json
  def destroy
    @hotel.destroy
    respond_to do |format|
      format.html { redirect_to hotels_url, notice: 'Hotel excluído com sucesso.' }
      format.json { head :no_content }
    end
  end
 
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotel
      @hotel = Hotel.find(params[:id])
    end

    def set_state_options
      @state_options = State.order(:uf).pluck(:uf, :id)
    end

    # Only allow a list of trusted parameters through.
    def hotel_params
      params.require(:hotel).permit(:sname, :short_name, :document, :email, :address, :neighborhood, :city, :state_id,
                                     :zipcode, :phone, :phone2, :fax, :contact, :comments, :Valordiaria)
    end
end
