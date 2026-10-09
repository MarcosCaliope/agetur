class SordersController < ApplicationController
# No Before Action nós adicionamos também o export para que ele consiga pegar o agreement correto  

  before_action :set_sorder, only: [:show, :edit, :update, :destroy, :export]
  before_action :set_destination_options, only: [:new, :create, :edit, :update]
  before_action :set_tourguide_options, only: [:new, :create, :edit, :update]
  before_action :set_driver_options, only: [:new, :create, :edit, :update]
  before_action :set_vehicle_options, only: [:new, :create, :edit, :update]

  before_action :set_customer_options, only: [:new, :create, :edit, :update]
  before_action :set_hotel_options, only: [:new, :create, :edit, :update]
  before_action :set_vendor_options, only: [:new, :create, :edit, :update]
  before_action :set_agency_options, only: [:new, :create, :edit, :update]
  before_action :set_company_options, only: [:new, :create, :edit, :update]

  #before_action :sorder_params, only: [:show, :edit, :update, :destroy]
  before_action :set_sorder_item, only: [:show, :edit, :update, :destroy]
  # GET /sorders
  # GET /sorders.json
  def index
    @q = Sorder.ransack(params[:q])
    @sorders = @q.result
    
    #@sorders = Sorder.all
    respond_to do |format|
      format.html
      format.pdf do
        #pdf = Prawn::Document.new
        pdf = SorderPdf.new (@sorders)
        #pdf.text "Hello"
        send_data pdf.render, filename: 'sorder.pdf', type: 'application/pdf', disposition: "inline"
      end
    end
  end



  # GET /sorders/1/export
  def export
    pdf = SorderExportPdf.new(@sorder)
    send_data pdf.render, filename: "sorder_#{@sorder.id}.pdf", type: 'application/pdf', disposition: "inline"
  end

  # GET /sorders/1
  # GET /sorders/1.json
  def show
    #só coloquei aqui para testar order_params
    #@sorder = Sorder.find(params[:id])
    #@sorder_item = SorderItem.where('id = ?', params[:id])
    #@parametros = params
    # testando o wicked pdf ===================
    #respond_to do |format|
    #  format.html
    #  format.pdf do
    #    render pdf: "sorder",
    #    template: "sorders/show.html.erb"
    #    layout: 'pdf.html'
    #  end
    # end
    #===========================================

  end

  # GET /sorders/new
  def new
    @sorder = Sorder.new
  end

  # GET /sorders/1/edit
  def edit
  end

  # POST /sorders
  # POST /sorders.json
  def create
    @sorder = Sorder.new(sorder_params)

    respond_to do |format|
      if @sorder.save
        format.html { redirect_to @sorder, notice: 'Ordem de serviço criada com sucesso.' }
        format.json { render :show, status: :created, location: @sorder }
      else
        format.html { render :new }
        format.json { render json: @sorder.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sorders/1
  # PATCH/PUT /sorders/1.json
  def update
    respond_to do |format|
      if @sorder.update(sorder_params)
        format.html { redirect_to @sorder, notice: 'Ordem de serviço atualizada com sucesso.' }
        format.json { render :show, status: :ok, location: @sorder }
      else
        format.html { render :edit }
        format.json { render json: @sorder.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sorders/1
  # DELETE /sorders/1.json
  def destroy
    @sorder.destroy
    respond_to do |format|
      format.html { redirect_to sorders_url, notice: 'Ordem de serviço excluída com sucesso.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sorder
      @sorder = Sorder.find(params[:id])
    end
    def set_sorder_item
      @sorder_item = SorderItem.where('sorder_id = ?', params[:id]).includes(:companions)
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

    def set_customer_options
      @customer_options = Customer.all.pluck(:nome, :id)
    end

    def set_hotel_options
      @hotel_options = Hotel.all.pluck(:sname, :id)
    end

    def set_vendor_options
      em_uso = @sorder ? @sorder.sorder_items.filter_map(&:vendor_id) : []
      @vendor_options = Vendor.ativos.or(Vendor.where(id: em_uso)).order(:sname).pluck(:sname, :id)
    end

    def set_agency_options
      @agency_options = Agency.all.pluck(:sname, :id)
    end
    def set_company_options
      @company_options = Company.all.pluck(:name, :id)
    end

    # Only allow a list of trusted parameters through.
    def sorder_params
      params.require(:sorder).permit(:data, :sobservacoes, :destination_id, :tourguide_id, :driver_id, :vehicle_id, :company_id,
      :valorguia, :valormotorista, :valorpedagio, :valordespesas, :valorcombustivel, :valoros, :valorfinalos,
      sorder_items_attributes: [:id, :sorder, :comments, :customer_id, :documenttype, :document, :hotel_id, :apto, 
      :vendor_id, :agency_id, :phone, :qtdepax, :qtdechd, :hour, :amount,
      :amountpay, :amountcomission, :amountcomissionpay, :amountcomissionrep, :amountcomissionreppay, :snomepax, :scancelado, :done, :_destroy,
      companions_attributes: [:id, :snome, :documenttype, :document, :chd, :colo, :_destroy]])
    end
end
