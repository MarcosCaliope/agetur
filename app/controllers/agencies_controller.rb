class AgenciesController < ApplicationController
  before_action :set_agency, only: [:show, :edit, :update, :destroy]
  before_action :set_state_options, only: [:new, :create, :edit, :update]

  # GET /agencies
  # GET /agencies.json
  def index
    @agencies = Agency.pesquisar(params[:busca]).includes(:state).order(:id)
  end

  # GET /agencies/1
  # GET /agencies/1.json
  def show
  end

  # GET /agencies/new
  def new
    @agency = Agency.new
  end

  # GET /agencies/1/edit
  def edit
  end

  # POST /agencies
  # POST /agencies.json
  def create
    @agency = Agency.new(agency_params)

    respond_to do |format|
      if @agency.save
        format.html { redirect_to @agency, notice: 'Agência criada com sucesso.' }
        format.json { render :show, status: :created, location: @agency }
      else
        format.html { render :new }
        format.json { render json: @agency.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /agencies/1
  # PATCH/PUT /agencies/1.json
  def update
    respond_to do |format|
      if @agency.update(agency_params)
        format.html { redirect_to @agency, notice: 'Agência atualizada com sucesso.' }
        format.json { render :show, status: :ok, location: @agency }
      else
        format.html { render :edit }
        format.json { render json: @agency.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /agencies/1
  # DELETE /agencies/1.json
  def destroy
    @agency.destroy
    respond_to do |format|
      format.html { redirect_to agencies_url, notice: 'Agência excluída com sucesso.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_agency
      @agency = Agency.find(params[:id])
    end

    def set_state_options
      @state_options = State.order(:uf).pluck(:uf, :id)
      @vendor_options = Vendor.order(:sname).pluck(:sname, :id)
    end

    # Only allow a list of trusted parameters through.
    def agency_params
      params.require(:agency).permit(:sname, :short_name, :document, :email, :address, :neighborhood, :city, :state_id,
                                     :zipcode, :phone, :phone2, :fax, :contact, :comments, :commission, :vendor_id)
    end
end
