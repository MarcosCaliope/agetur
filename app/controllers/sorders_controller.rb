class SordersController < ApplicationController
  # Paid amounts are moved by passenger payments and commission payments;
  # only an admin may correct them in the form.
  PAGOS = %i[amountpay amountcomissionpay amountcomissionreppay].freeze

# No Before Action nós adicionamos também o export para que ele consiga pegar o agreement correto  

  before_action :set_sorder, only: [:show, :edit, :update, :destroy, :export, :encerrar, :reabrir, :editando]
  before_action :exigir_ordem_aberta, only: [:edit, :update, :destroy]
  before_action :set_destination_options, only: [:new, :create, :edit, :update]
  before_action :set_tourguide_options, only: [:new, :create, :edit, :update]
  before_action :set_driver_options, only: [:new, :create, :edit, :update]
  before_action :set_vehicle_options, only: [:new, :create, :edit, :update]

  before_action :set_customer_options, only: [:new, :create, :edit, :update]
  before_action :set_hotel_options, only: [:new, :create, :edit, :update]
  before_action :set_vendor_options, only: [:new, :create, :edit, :update]
  before_action :set_agency_options, only: [:new, :create, :edit, :update]

  #before_action :sorder_params, only: [:show, :edit, :update, :destroy]
  before_action :set_sorder_item, only: [:show, :edit, :update, :destroy]
  # GET /sorders
  # GET /sorders.json
  def index
    @q = Sorder.ransack(params[:q])
    @sorders = @q.result

    #@sorders = Sorder.all
    respond_to do |format|
      format.html do
        # PAX/CHD of the active passengers, one query for the whole list.
        @pax = SorderItem.ativos.where(sorder_id: @sorders.select(:id))
          .group(:sorder_id).pluck(:sorder_id, Arel.sql("SUM(qtdepax)"), Arel.sql("SUM(qtdechd)"))
          .to_h { |id, pax, chd| [id, [pax.to_i, chd.to_i]] }
      end
      format.pdf do
        #pdf = Prawn::Document.new
        pdf = SorderPdf.new (@sorders)
        #pdf.text "Hello"
        send_data pdf.render, filename: 'sorder.pdf', type: 'application/pdf', disposition: "inline"
      end
    end
  end



  # PATCH /sorders/1/encerrar
  def encerrar
    antes = @sorder.payables.count
    @sorder.encerrar!
    geradas = @sorder.payables.count - antes
    redirect_to @sorder, notice: "Ordem de serviço encerrada. #{geradas} conta(s) a pagar gerada(s)."
  end

  # PATCH /sorders/1/reabrir
  def reabrir
    @sorder.reabrir!
    redirect_to @sorder, notice: "Ordem de serviço reaberta. As contas a pagar dela ainda não pagas foram removidas."
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
    @sorder.registrar_edicao!(usuario_atual)
    @outros_editando = @sorder.outros_editando(usuario_atual)
  end

  # PATCH /sorders/1/editando: the open edit form says it's still open and
  # learns who else is editing. DELETE: the form was left.
  def editando
    if request.delete?
      @sorder.encerrar_edicao!(usuario_atual)
      head :no_content
    else
      @sorder.registrar_edicao!(usuario_atual)
      render json: { outros: @sorder.outros_editando(usuario_atual).map { |edicao| descrever_edicao(edicao) } }
    end
  end

  # POST /sorders
  # POST /sorders.json
  def create
    @sorder = Sorder.new(sorder_params)

    respond_to do |format|
      if @sorder.save
        format.html { redirect_to @sorder, notice: com_agendamentos('Ordem de serviço criada com sucesso.') }
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
    # The version the form was opened with (Sorder#lock_version): the row is
    # locked and a save over someone else's change is refused.
    versao = params.dig(:sorder, :lock_version).presence&.to_i
    salvo = false
    Sorder.transaction do
      @sorder.lock!
      raise ActiveRecord::StaleObjectError.new(@sorder, "update") if versao && versao != @sorder.lock_version

      salvo = @sorder.update(sorder_params)
      raise ActiveRecord::Rollback unless salvo
    end
    respond_to do |format|
      if salvo
        @sorder.encerrar_edicao!(usuario_atual)
        format.html { redirect_to @sorder, notice: com_agendamentos('Ordem de serviço atualizada com sucesso.') }
        format.json { render :show, status: :ok, location: @sorder }
      else
        format.html { render :edit }
        format.json { render json: @sorder.errors, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    # Someone else saved the order, or took a payment on it, since this form
    # was opened. The form comes back as typed, still with the old version.
    @conflito = true
    begin
      @sorder.assign_attributes(sorder_params)
    rescue ActiveRecord::RecordNotFound # a passenger it lists was removed
    end
    @sorder.lock_version = versao
    @outros_editando = @sorder.outros_editando(usuario_atual)
    respond_to do |format|
      format.html do
        flash.now[:alert] = "Esta ordem de serviço foi alterada por outro usuário enquanto você editava, e suas alterações não foram " \
                            "gravadas. Abra a ordem de novo para ver a versão atual e refaça as alterações."
        render :edit, status: :conflict
      end
      format.json { render json: { error: "Ordem alterada por outro usuário." }, status: :conflict }
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

    # Brings in the booked tours of the order's destination and date, and
    # says which (Sorder#incluir_agendamentos!).
    def com_agendamentos(mensagem)
      resultado = @sorder.incluir_agendamentos!.group_by(&:first)
      nomes = ->(tipo) { resultado.fetch(tipo, []).map { |_, passeio, erro| [passeio.booking.snome, (" (#{erro})" if erro)].join } }
      [mensagem,
       ("Agendados incluídos: #{nomes[:incluido].to_sentence}." if resultado[:incluido]),
       ("Vinculados ao agendamento: #{nomes[:vinculado].to_sentence}." if resultado[:vinculado]),
       ("Agendados não incluídos: #{nomes[:erro].to_sentence}." if resultado[:erro])].compact.join(" ")
    end

    def descrever_edicao(edicao)
      "#{edicao.usuario} (desde #{I18n.l(edicao.visto_em, format: '%H:%M')})"
    end
    helper_method :descrever_edicao

    # A closed order (SISTGER's iFlgAberto) can't be changed until reopened.
    def exigir_ordem_aberta
      redirect_to @sorder, alert: "Ordem de serviço encerrada: reabra para alterar." if @sorder.encerrada?
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

    # Only allow a list of trusted parameters through.
    def sorder_params
      params.require(:sorder).permit(:data, :sobservacoes, :destination_id, :tourguide_id, :driver_id, :vehicle_id,
      :valorguia, :valormotorista, :valorpedagio, :valordespesas, :valorcombustivel, :valoros, :valorfinalos,
      sorder_items_attributes: [:id, :sorder, :comments, :customer_id, :documenttype, :document, :hotel_id, :apto, 
      :vendor_id, :agency_id, :phone, :qtdepax, :qtdechd, :hour, :amount,
      :discount, :vendor_discount, :amountcomission, :amountcomissionrep, :snomepax, :scancelado, :forma_pagamento, :done, :_destroy,
      *(PAGOS if admin_signed_in?),
      companions_attributes: [:id, :snome, :documenttype, :document, :chd, :colo, :_destroy]])
    end
end
