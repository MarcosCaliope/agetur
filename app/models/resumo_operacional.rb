# Resumo operacional (SISTGER's "Resumo Operacional Ordem de Serviço",
# frmRelResumoOperacionalOS): every order in a period, by number, with its
# costs (Sorder::CUSTOS) and, from its active passengers, the tour value
# (less both discounts) and the vendors' commissions. As SISTGER prints it,
# the order's total is value − commissions − costs, computed here instead
# of read from the stored valoros/valorfinalos, which only the legacy form
# kept up to date.
class ResumoOperacional
  Linha = Struct.new(:sorder, :valor, :comissoes) do
    def custo(coluna) = sorder.public_send(coluna).to_f
    def despesas = Sorder::CUSTOS.sum { |coluna, *| custo(coluna) }
    def total = valor - comissoes - despesas
  end

  attr_reader :inicio, :fim

  def initialize(params)
    hoje = Time.zone.today
    @inicio = data_param(params[:inicio]) || hoje.beginning_of_month
    @fim = data_param(params[:fim]) || hoje
  end

  def linhas
    @linhas ||= begin
      ordens = Sorder.where(data: inicio.beginning_of_day..fim.end_of_day).includes(:destination, :tourguide, :vehicle).order(:id).to_a
      somas = SorderItem.ativos.where(sorder_id: ordens.map(&:id)).group(:sorder_id).pluck(
        :sorder_id,
        Arel.sql("SUM(COALESCE(amount, 0) - COALESCE(discount, 0) - COALESCE(vendor_discount, 0))"),
        Arel.sql("SUM(COALESCE(amountcomission, 0))")
      ).to_h { |id, valor, comissoes| [id, [valor.to_f, comissoes.to_f]] }
      ordens.map { |sorder| Linha.new(sorder, *somas.fetch(sorder.id, [0.0, 0.0])) }
    end
  end

  def totais
    { valor: linhas.sum(&:valor), comissoes: linhas.sum(&:comissoes), despesas: linhas.sum(&:despesas), total: linhas.sum(&:total) }
  end

  def titulo
    "Resumo operacional das ordens de serviço de #{I18n.l(inicio)} a #{I18n.l(fim)}"
  end

  private

  def data_param(valor)
    Date.iso8601(valor.to_s) if valor.present?
  rescue Date::Error
    nil
  end
end
