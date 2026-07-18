class ServiceOrdersController < ApplicationController
  before_action :set_service_order, only: [:show, :edit, :update, :destroy]
  before_action :set_destination_options, only: [:new, :create, :edit, :update]
  before_action :set_tourguide_options, only: [:new, :create, :edit, :update]
  before_action :set_driver_options, only: [:new, :create, :edit, :update]
  before_action :set_vehicle_options, only: [:new, :create, :edit, :update]
  
  before_action :set_service_order_item, only: [:show, :edit, :update, :destroy]

  # Nós incluimos aqui a lib que vamos criar chamada generate_pdf.rb
  require './lib/generate_pdf'

  # GET /service_orders
  # GET /service_orders.json
  def index
    @service_orders = ServiceOrder.all.includes(:service_order_item)
    #@service_orders = ServiceOrder.all.includes(:invoice_items)
 
    #respond_to do |format|
    #  format.html
    #  format.pdf do
    #    render pdf: "ServiceOrder",
    #    template: "service_orders/show.html.erb"
    #    #layout: "pdf.html"
    #  end
  #end
end

  # GET /service_orders/1
  # GET /service_orders/1.json
  def  show
    # outro modo com wicked
    #@invoice = scope.find(params[:id])
    @service_order = ServiceOrder.find(params[:id])
    respond_to do |format|
        format.html
        format.pdf do
            render pdf: "Invoice No. #{@ServiceOrder.id}",
            page_size: 'A4',
            template: "ServiceOrder/show.html.erb",
            layout: "pdf.html",
            orientation: "Landscape",
            lowquality: true,
            zoom: 1,
            dpi: 75
        end
    end    
    # fim
    # incluindo opção para o Wicked-pdf
    #@service_orders = scope.find(params[:id])

    #respond_to do |format|
    #    format.html
    #    format.pdf do
    #      render pdf: "ServiceOrderItem",
    #      template: "service_orders/show.html.erb"
    #      #layout: "pdf.html.erb"
    #    end
    #end
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
# metodo para wicked
    #def scope
    #  ::ServiceOrder.all.includes(:ServiceOrderItem)
    # end


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
