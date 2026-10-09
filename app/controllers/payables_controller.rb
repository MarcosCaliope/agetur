# Contas a pagar: bills made by closing orders (commissions and costs) and
# typed-in ones, paid through the cash book.
class PayablesController < ApplicationController
  before_action :set_payable, only: %i[edit update destroy pagamento pagar estornar]
  before_action :exigir_aberta, only: %i[edit update destroy pagamento pagar]

  # GET /contas-a-pagar?situacao=abertas|pagas|todas&tipo=&inicio=&fim=&busca=
  def index
    @situacao = %w[abertas pagas todas].include?(params[:situacao]) ? params[:situacao] : "abertas"
    contas = Payable.all
    contas = contas.public_send(@situacao) unless @situacao == "todas"
    contas = contas.where(tipo: params[:tipo]) if Payable::TIPOS.key?(params[:tipo])
    contas = contas.where(cash_entry_id: params[:lancamento]) if params[:lancamento].present?
    contas = contas.where(vencimento: data_param(:inicio)..) if data_param(:inicio)
    contas = contas.where(vencimento: ..data_param(:fim)) if data_param(:fim)
    if params[:busca].present?
      termo = "%#{Payable.sanitize_sql_like(params[:busca].squish)}%"
      contas = contas.where("unaccent(payables.descricao) ILIKE unaccent(:t) OR unaccent(payables.credor_nome) ILIKE unaccent(:t)", t: termo)
    end
    @payables = contas.preload(:credor).order(:vencimento, :id)
    @total = contas.sum(:valor)
  end

  def new
    @payable = Payable.new(tipo: "avulsa", vencimento: Time.zone.today)
  end

  def edit; end

  def create
    @payable = Payable.new(payable_params.merge(tipo: "avulsa"))
    if @payable.save
      redirect_to payables_path, notice: "Conta a pagar criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @payable.update(payable_params)
      redirect_to payables_path, notice: "Conta a pagar atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @payable.destroy!
    redirect_to payables_path, notice: "Conta a pagar excluída com sucesso."
  end

  # GET /contas-a-pagar/1/pagamento
  def pagamento; end

  # PATCH /contas-a-pagar/1/pagar
  def pagar
    dados = params.require(:pagamento).permit(:data, :forma_pagamento, :valor)
    @payable.pagar!(data: dados[:data].presence, forma_pagamento: dados[:forma_pagamento], valor: dados[:valor].presence,
                    usuario: usuario_atual)
    redirect_to payables_path, notice: "Conta paga e lançada no caixa."
  rescue ActiveRecord::RecordInvalid => e
    @erros = e.record.errors.full_messages
    render :pagamento, status: :unprocessable_entity
  end

  # PATCH /contas-a-pagar/1/estornar
  def estornar
    @payable.estornar!
    redirect_to payables_path(situacao: "abertas"), notice: "Pagamento estornado e retirado do caixa."
  end

  private

  def set_payable
    @payable = Payable.find(params[:id])
  end

  def exigir_aberta
    redirect_to payables_path, alert: "Conta já paga: estorne o pagamento para alterá-la." if @payable.pago?
  end

  def data_param(nome)
    Date.iso8601(params[nome]) if params[nome].present?
  rescue Date::Error
    nil
  end

  def payable_params
    params.require(:payable).permit(:descricao, :credor_nome, :valor, :vencimento, :observacoes)
  end
end
