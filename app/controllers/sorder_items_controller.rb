class SorderItemsController < SordersController
  before_action :set_sorder_item, only: [:show, :edit, :update, :destroy]
# Incluimos a Lib que vamos criar para podermos chama-la no nosso método
require './lib/generate_pdf'
  # GET /sorder_items
  # GET /sorder_items.json
  def index
    @sorder_items = SorderItem.all
  end

  # GET /sorder_items/1
  # GET /sorder_items/1.json
  def show
    respond_to do |format|
      format.html
      format.pdf do
        #pdf = Prawn::Document.new
        pdf = SorderitensPdf.new (@sorders)
        #send_data pdf.render, filename: 'sorder.pdf', type: 'application/pdf', disposition: "inline"
        # quando não aciona o index.pdf.prawn
      end
    end
end

  # GET /sorder_items/new
  def new
    @sorder_item = SorderItem.new
  end

  # GET /sorder_items/1/edit
  def edit
  end

  # POST /sorder_items
  # POST /sorder_items.json
  def create
    @sorder_item = SorderItem.new(sorder_item_params)

    respond_to do |format|
      if @sorder_item.save
        format.html { redirect_to @sorder_item, notice: 'Sorder item was successfully created.' }
        format.json { render :show, status: :created, location: @sorder_item }
      else
        format.html { render :new }
        format.json { render json: @sorder_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sorder_items/1
  # PATCH/PUT /sorder_items/1.json
  def update
    respond_to do |format|
      if @sorder_item.update(sorder_item_params)
        format.html { redirect_to @sorder_item, notice: 'Sorder item was successfully updated.' }
        format.json { render :show, status: :ok, location: @sorder_item }
      else
        format.html { render :edit }
        format.json { render json: @sorder_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sorder_items/1
  # DELETE /sorder_items/1.json
  def destroy
    @sorder_item.destroy
    respond_to do |format|
      format.html { redirect_to sorder_items_url, notice: 'Sorder item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
 # Criamos o método export para chamar a lib que gera o PDF e depois redirecionar o usuário para baixo o PDF
  def export
   # GeneratePdf::sorder_item(@SorderItem.all.map {|s| [s.comments, s.id]})
    #GeneratePdf::sorder_item(@SorderItem.id, @SorderItem.destination_id)
    redirect_to '/sorder_item.pdf'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sorder_item
      @sorder_item = SorderItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sorder_item_params
      params.require(:sorder_item).permit(:sorder_id, :comments)
    end
end
