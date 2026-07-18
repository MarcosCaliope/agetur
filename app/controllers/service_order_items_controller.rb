class ServiceOrderItemsController < ApplicationController
  before_action :set_service_order_item, only: [:show, :edit, :update, :destroy]

  before_action :set_service_orderid_options, only: [:new, :create, :edit, :update]
  before_action :set_service_order_options, only: [:new, :create, :edit, :update]
  before_action :set_hotel_options, only: [:new, :create, :edit, :update]
  before_action :set_vendor_options, only: [:new, :create, :edit, :update]
  before_action :set_agency_options, only: [:new, :create, :edit, :update]

  # GET /service_order_items
  # GET /service_order_items.json
  def index
    @service_order_items = ServiceOrderItem.all
  end

  # GET /service_order_items/1
  # GET /service_order_items/1.json
  def show
  end

  # GET /service_order_items/new
  def new
    @service_order_item = ServiceOrderItem.new
  end

  # GET /service_order_items/1/edit
  def edit
  end

  # POST /service_order_items
  # POST /service_order_items.json
  def create
    @service_order_item = ServiceOrderItem.new(service_order_item_params)

    respond_to do |format|
      if @service_order_item.save
        format.html { redirect_to @service_order_item, notice: 'Service order item was successfully created.' }
        format.json { render :show, status: :created, location: @service_order_item }
      else
        format.html { render :new }
        format.json { render json: @service_order_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /service_order_items/1
  # PATCH/PUT /service_order_items/1.json
  def update
    respond_to do |format|
      if @service_order_item.update(service_order_item_params)
        format.html { redirect_to @service_order_item, notice: 'Service order item was successfully updated.' }
        format.json { render :show, status: :ok, location: @service_order_item }
      else
        format.html { render :edit }
        format.json { render json: @service_order_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /service_order_items/1
  # DELETE /service_order_items/1.json
  def destroy
    @service_order_item.destroy
    respond_to do |format|
      format.html { redirect_to service_order_items_url, notice: 'Service order item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # Criamos o método export para chamar a lib que gera o PDF e depois redirecionar o usuário para baixo o PDF
  def export
    GeneratePdf::spending(service_order_item.all.map {|s| [s.section, s.value.to_f]})
    redirect_to '/service_order_item.pdf'
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_service_order_item
      @service_order_item = ServiceOrderItem.find(params[:id])
    end
    
    def set_service_orderid_options
      @service_orderid_options = ServiceOrder.all.pluck(:id)
    end

    def set_service_order_options
      @service_order_options = ServiceOrder.all.pluck(:destination_id, :id)
    end

    def set_hotel_options
      @hotel_options = Hotel.all.pluck(:sname, :id)
    end
    
    def set_vendor_options
      @vendor_options = Vendor.all.pluck(:sname, :id)
    end
    
    def set_agency_options
      @agency_options = Agency.all.pluck(:sname, :id)
  end

    # Only allow a list of trusted parameters through.
    def service_order_item_params
      params.require(:service_order_item).permit(:service_order_id, :nomepax, :documenttype, :document, :hotel_id, :apto, :qtdepax, :hour, :phone, :vendor_id, :agency_id, :amount, :amountpay, :amountcomission, :comments)
    end
end
