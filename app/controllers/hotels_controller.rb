class HotelsController < ApplicationController
  before_action :set_hotel, only: [:show, :edit, :update, :destroy, :export]

   # Nós incluimos aqui a lib que vamos criar chamada generate_pdf.rb
  
  # GET /hotels
  # GET /hotels.json
  def index
    #@hotels = Hotel.order("id.Desc").all
    #@hotels = Hotel.all
    @q = Hotel.ransack(params[:q])
    @hotels = @q.result
 
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
        format.html { redirect_to @hotel, notice: 'Hotel foi criado com sucesso.' }
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
        format.html { redirect_to @hotel, notice: 'Hotel was successfully updated.' }
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
      format.html { redirect_to hotels_url, notice: 'Hotel was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
 
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotel
      @hotel = Hotel.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotel_params
      params.require(:hotel).permit(:sname, :email, :address, :phone, :comments, :Valordiaria)
    end
end
