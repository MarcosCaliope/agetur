# Caixa: the cash book for a period, with totals per payment method and the
# balance carried over. Entries made by passenger payments and paid bills
# are listed but changed only from there.
class CashEntriesController < ApplicationController
  before_action :set_cash_entry, only: %i[edit update destroy]
  before_action :exigir_manual, only: %i[edit update destroy]

  # GET /caixa?inicio=&fim=
  def index
    hoje = Time.zone.today
    @inicio = data_param(:inicio) || hoje
    @fim = data_param(:fim) || @inicio
    @inicio, @fim = @fim, @inicio if @inicio > @fim

    periodo = CashEntry.where(data: @inicio..@fim)
    @lancamentos = periodo.includes(:pagamento, :payable).order(:data, :id)
    @saldo_anterior = CashEntry.where(data: ...@inicio).saldo
    @entradas = periodo.entradas.sum(:valor)
    @saidas = periodo.saidas.sum(:valor)
    @por_forma = periodo.group(:forma_pagamento, :tipo).sum(:valor)
  end

  def new
    @cash_entry = CashEntry.new(data: Time.zone.today, tipo: "S", forma_pagamento: "D", categoria: "Despesa")
  end

  def edit; end

  def create
    @cash_entry = CashEntry.new(cash_entry_params.merge(usuario: usuario_atual))
    if @cash_entry.save
      redirect_to cash_entries_path(inicio: @cash_entry.data), notice: "Lançamento de caixa criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @cash_entry.update(cash_entry_params)
      redirect_to cash_entries_path(inicio: @cash_entry.data), notice: "Lançamento de caixa atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @cash_entry.destroy!
    redirect_to cash_entries_path(inicio: @cash_entry.data), notice: "Lançamento de caixa excluído com sucesso."
  end

  private

  def set_cash_entry
    @cash_entry = CashEntry.find(params[:id])
  end

  def exigir_manual
    return unless @cash_entry.automatico?

    redirect_to cash_entries_path(inicio: @cash_entry.data),
                alert: "Este lançamento veio de um recebimento ou de uma conta paga: altere-o por lá."
  end

  def data_param(nome)
    Date.iso8601(params[nome]) if params[nome].present?
  rescue Date::Error
    nil
  end

  def cash_entry_params
    params.require(:cash_entry).permit(:data, :tipo, :categoria, :forma_pagamento, :valor, :descricao, :requerente, :documento)
  end
end
