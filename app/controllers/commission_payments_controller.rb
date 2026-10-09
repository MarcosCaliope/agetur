# Pagamento de comissões (SISTGER's frmPagamentoComissoes): the passengers
# with vendor (or repasse agency) commission left to pay, filtered by
# creditor, order date and order; the checked ones are paid in one go, with
# one cash exit and receipt per creditor. Orders don't need to be closed.
class CommissionPaymentsController < ApplicationController
  before_action :carregar

  # GET /comissoes/pagamento?tipo=&credor_id=&inicio=&fim=&sorder_id=
  def index
    @data = Time.zone.today
    @recibos = CashEntry.where(id: Array(params[:recibos])).order(:id)
  end

  # POST /comissoes/pagamento with itens[] (passenger ids), data, forma_pagamento
  def create
    ids = Array(params[:itens]).map(&:to_i)
    @data = (Date.iso8601(params[:data].to_s) rescue nil)
    escolhidos = @itens.select { |item| ids.include?(item.id) }
    return voltar("Marque ao menos um passageiro.") if escolhidos.empty?
    return voltar("Informe a data do pagamento.") unless @data

    saidas = Payable.transaction do
      contas = escolhidos.filter_map { |item| Payable.de_comissao(item, @tipo, vencimento: @data) }
      contas.each(&:save!)
      Payable.pagar_em_lote!(contas, data: @data, forma_pagamento: params[:forma_pagamento], usuario: usuario_atual)
    end
    redirect_to pagamento_comissoes_path(filtros.merge(recibos: saidas.map(&:id))),
                notice: "#{escolhidos.size} comissão(ões) paga(s) em #{saidas.size} saída(s) no caixa."
  rescue ActiveRecord::RecordInvalid => e
    voltar("Pagamento não feito: #{e.record.errors.full_messages.to_sentence}")
  end

  private

  def carregar
    @tipo = Payable::COMISSOES.key?(params[:tipo]) ? params[:tipo] : "comissao_vendedor"
    vendedor = @tipo == "comissao_vendedor"
    hoje = Time.zone.today
    @inicio = data_param(:inicio) || (hoje.beginning_of_month unless filtros_informados?)
    @fim = data_param(:fim) || (hoje unless filtros_informados?)

    itens = SorderItem.ativos.joins(:sorder).includes(:sorder, :vendor, :agency)
    if vendedor
      itens = itens.joins(:vendor).where(vendors: { no_commission: [false, nil] })
                   .where("COALESCE(amountcomission, 0) - COALESCE(amountcomissionpay, 0) >= 0.01")
      itens = itens.where(vendor_id: params[:credor_id]) if params[:credor_id].present?
    else
      itens = itens.where.not(agency_id: nil).where("COALESCE(amountcomissionrep, 0) - COALESCE(amountcomissionreppay, 0) >= 0.01")
      itens = itens.where(agency_id: params[:credor_id]) if params[:credor_id].present?
    end
    itens = itens.where(sorders: { data: @inicio.beginning_of_day.. }) if @inicio
    itens = itens.where(sorders: { data: ..@fim.end_of_day }) if @fim
    itens = itens.where(sorder_id: params[:sorder_id]) if params[:sorder_id].present?
    @itens = itens.order("sorders.data", :sorder_id, :id).to_a

    @abertas = Payable.abertas.where(sorder_item_id: @itens.map(&:id), origem: Payable::COMISSOES[@tipo]).index_by(&:sorder_item_id)
    @credores = vendedor ? Vendor.order(:sname).pluck(:sname, :id) : Agency.order(:sname).pluck(:sname, :id)
  end

  # Without creditor, order or dates, the list defaults to this month.
  def filtros_informados?
    %i[credor_id sorder_id inicio fim].any? { |nome| params[nome].present? }
  end

  def filtros
    { tipo: @tipo, credor_id: params[:credor_id].presence, sorder_id: params[:sorder_id].presence,
      inicio: @inicio, fim: @fim }.compact
  end
  helper_method :filtros

  def voltar(mensagem)
    redirect_to pagamento_comissoes_path(filtros), alert: mensagem
  end

  def data_param(nome)
    Date.iso8601(params[nome]) if params[nome].present?
  rescue Date::Error
    nil
  end
end
