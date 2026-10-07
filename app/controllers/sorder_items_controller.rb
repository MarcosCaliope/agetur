class SorderItemsController < ApplicationController
  before_action :set_sorder_item, only: [:show, :edit, :update, :destroy]
  # GET /sorder_items
  # GET /sorder_items.json
  def index
    @sorder_items = SorderItem.all
  end

  # GET /sorder_items/1
  # GET /sorder_items/1.json
  def show
  end

  # GET /showcomis
  def showcomis
    @q = SorderItem.ransack(comissoes_query)
    @sorder_items = @q.result.includes(:vendor, :hotel, :customer).order(:created_at)
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sorder_item
      @sorder_item = SorderItem.find(params[:id])
    end

    # The date fields send plain dates, so make "Data Final" include that whole day.
    def comissoes_query
      q = params.fetch(:q, {}).permit(:created_at_gteq, :created_at_lteq, :vendor_id_eq).to_h
      q[:created_at_lteq] = Time.zone.parse(q[:created_at_lteq])&.end_of_day if q[:created_at_lteq].present?
      q
    end

    # Only allow a list of trusted parameters through.
    def sorder_item_params
      params.require(:sorder_item).permit(:sorder_id, :comments)
    end
end
