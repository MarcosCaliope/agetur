class ServiceOrdersController < ApplicationController
  before_action :set_service_order, only: [:show, :edit, :update, :destroy]
  before_action :set_destination_options, only: [:new, :create, :edit, :update]
  before_action :set_tourguide_options, only: [:new, :create, :edit, :update]
  before_action :set_driver_options, only: [:new, :create, :edit, :update]
  before_action :set_vehicle_options, only: [:new, :create, :edit, :update]
  
  before_action :set_service_order_item, only: [:show, :edit, :update, :destroy]

  # GET /service_orders
  # GET /service_orders.json
  def index
    @service_orders = ServiceOrder.all
  end

  # GET /service_orders/1
  # GET /service_orders/1.json
  def show
  end

  # GET /service_orders/new
  def new
    @service_order = ServiceOrder.new
  end

  # GET /service_orders/1/edit
  def edit
  end

  # POST /service_orders
  # POST /service_orders.json
  def create
    @service_order = ServiceOrder.new(service_order_params)

    respond_to do |format|
      if @service_order.save
        format.html { redirect_to @service_order, notice: 'Service order was successfully created.' }
        format.json { render :show, status: :created, location: @service_order }
      else
        format.html { render :new }
        format.json { render json: @service_order.errors, status: :unprocessable_entity }
      end
    end
  
  end

  # PATCH/PUT /service_orders/1
  # PATCH/PUT /service_orders/1.json
  def update
    respond_to do |format|
      if @service_order.update(service_order_params)
        format.html { redirect_to @service_order, notice: 'Service order was successfully updated.' }
        format.json { render :show, status: :ok, location: @service_order }
      else
        format.html { render :edit }
        format.json { render json: @service_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /service_orders/1
  # DELETE /service_orders/1.json
  def destroy
    @service_order.destroy
    respond_to do |format|
      format.html { redirect_to service_orders_url, notice: 'Service order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_service_order
      @service_order = ServiceOrder.find(params[:id])
    end
    
    def set_service_order_item
      @service_order_item = ServiceOrderItem.where('service_order_id = ?', params[:id])
    end
    
    def set_service_orderid_options
      @service_orderid_options = ServiceOrder.all.pluck(:id)
    end
    
    def set_destination_options
      @destination_options = Destination.all.pluck(:description, :id)
    end

    def set_tourguide_options
      @tourguide_options = Tourguide.all.pluck(:sname, :id)
    end

    def set_driver_options
      @driver_options = Driver.all.pluck(:sname, :id)
    end

    def set_vehicle_options
      @vehicle_options = Vehicle.all.pluck(:license, :id)
    end

    # Only allow a list of trusted parameters through.
    def service_order_params
      params.require(:service_order).permit(:data, :destination_id, :tourguide_id, :driver_id, :vehicle_id, :valorguia, :valormotorista, :valorpedagio, :valordespesas, :valorcombustivel, :valoros, :valorfinalos, :bpagto, :bcancelado, :icapacidade, :ibloqueio, :iflgaberto, :ilitros, :sobservacoes, :sodometroinicio, :sodometrofim, :service_order_id)
    end
end
