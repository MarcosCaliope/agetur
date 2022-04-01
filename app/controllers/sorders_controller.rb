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
        # pesquisa não restritiva
        #@q = Sorder.ransack(params[:q].try(:merge, m: 'or'))
        #@sorders = Sorder.all
        #@sorders = Sorder.all.order(:data)
        respond_to do |format|
          format.html
          format.pdf do
            #pdf = Prawn::Document.new
            #pdf = SorderPdf.new (@sorders)
            #pdf.text "Hello"  nesta chamada usa  modelo 'pdf\sorder_pdf'
            #send_data pdf.render, filename: 'sorder.pdf', type: 'application/pdf', disposition: "inline"
            # quando não aciona o index.pdf.prawn
          end
        end
      end
    
    
    
      # Criamos este método que vai chamar nossa lib para gerar o PDF e depois redirecionar o user para o arquivo PDF
      #def export
      #  GeneratePdf::sorder(@sorders.id, @sorders.data, @sorders.destination_id)
      #  redirect_to '/sorder.pdf'
      #  GeneratePdf::sorder_item(@SorderItem.all.map {|s| [s.comments, s.id]})
       # redirect_to '/SorderItem.pdf'
      #end
     
      # GET /sorders/1
      # GET /sorders/1.json
      def show
        respond_to do |format|
          format.html
          format.pdf do
            #pdf = Prawn::Document.new
            #pdf = SorderitensPdf.new (@sorders)
            #send_data pdf.render, filename: 'sorder.pdf', type: 'application/pdf', disposition: "inline"
            # quando não aciona o index.pdf.prawn
          end
        end
      end
    
      def ShowComis
        @q = Sorder.ransack(params[:q])
        @sorders = @q.result
        respond_to do |format|
          format.html
        end
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
            format.html { redirect_to @sorder, notice: 'Sorder was successfully created.' }
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
        @sorder = Sorder.find(params[:id])
        
        #UPDATE Sorder SET totpax = sum(si.qtdepax) FROM sorder_item as si WHERE si.sorder_id=Sorder.id 

       #  UPDATE Sorder SET totpax=sum(si.qtdepax) WHERE Sorder.id  = si.sorder_id
       
       #UPDATE Sorder SET totpax = '(SELECT sum(qtdepax) FROM sorder_item where sorder_item.sorder_id = Sorder.id)'
        
        respond_to do |format|
          if @sorder.update(sorder_params)
            format.html { redirect_to @sorder, notice: 'Ordem Atualzada!!.' }
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
          format.html { redirect_to sorders_url, notice: 'Sorder was successfully destroyed.' }
          format.json { head :no_content }
        end
      end
    
      private
        # Use callbacks to share common setup or constraints between actions.
        def set_sorder
          @sorder = Sorder.find(params[:id])
        end
        def set_sorder_item
          @sorder_item = SorderItem.where('sorder_id = ?', params[:id])
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
          @vendor_options = Vendor.all.pluck(:sname, :id)
        end
    
        def set_agency_options
          @agency_options = Agency.all.pluck(:sname, :id)
        end
        def set_company_options
          @company_options = Company.all.pluck(:name, :cnpj, :address, :phone, :city, :state_id, :email, :site, :logoform, :logoentrada, :id)
        end
    
        # Only allow a list of trusted parameters through.
        def sorder_params
          params.require(:sorder).permit(:data, :sobservacoes, :destination_id, :tourguide_id, :driver_id, :vehicle_id,
          :valorguia, :valormotorista, :valorpedagio, :valordespesas, :valorcombustivel, :valoros, :valorfinalos, :dataos, :company_id,
          sorder_items_attributes: [:id, :sorder, :comments, :customer_id, :documenttype, :document, :hotel_id, :apto, 
          :vendor_id, :agency_id, :phone, :qtdepax, :qtdechd, :hour, :amount,
          :amountpay, :amountcomission, :amountcomissionpay, :amountcomissionrep, :amountcomissionreppay, :snomepax, :scancelado, :done, :_destroy])
        end
    end
    