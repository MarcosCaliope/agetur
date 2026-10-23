# Passeios repassados (SISTGER's "Relação de Repasses no Período",
# frmRelComissaoRepasse, the menu's "Relação de passeios repassados"): the
# passengers of the period's orders passed on to an agency (agency_id),
# grouped by that agency, with the amount left to receive and the repasse
# commission, paid and still to pay. Cancelled passengers show only on
# request and never count in the totals.
class PasseiosRepassados
  attr_reader :inicio, :fim, :agencia_id

  def initialize(params)
    hoje = Time.zone.today
    @inicio = data_param(params[:inicio]) || hoje.beginning_of_month
    @fim = data_param(params[:fim]) || hoje
    @agencia_id = params[:agencia_id].presence&.to_i
    @cancelados = params[:cancelados] == "1"
  end

  def cancelados? = @cancelados

  def itens
    @itens ||= begin
      escopo = SorderItem.joins(:sorder, :agency).where(sorders: { data: inicio.beginning_of_day..fim.end_of_day })
      escopo = escopo.ativos unless cancelados?
      escopo = escopo.where(agency_id: agencia_id) if agencia_id
      escopo.includes(:agency, :hotel, sorder: :destination)
        .order("agencies.sname", "sorders.data", :sorder_id, :sistger_sequencial, :id).to_a
    end
  end

  # [[agency, items]], by agency name.
  def grupos = itens.group_by(&:agency).to_a

  # Sums of the active items: count, :a_receber, :comissao, :paga, :a_pagar.
  def self.totais(itens)
    ativos = itens.reject(&:cancelado?)
    { quantidade: ativos.size,
      a_receber: ativos.sum(&:total_passeio),
      comissao: ativos.sum { |item| item.amountcomissionrep.to_f },
      paga: ativos.sum { |item| item.amountcomissionreppay.to_f },
      a_pagar: ativos.sum(&:comissao_repasse_a_pagar) }
  end

  def totais = self.class.totais(itens)

  def agencias = Agency.order(:sname)

  def agencia = (Agency.find_by(id: agencia_id) if agencia_id)

  def titulo
    texto = "Passeios repassados de #{I18n.l(inicio)} a #{I18n.l(fim)}"
    agencia ? "#{texto} - #{agencia.sname}" : texto
  end

  def params_url
    { inicio: inicio, fim: fim, agencia_id: agencia_id, cancelados: ("1" if cancelados?) }.compact
  end

  private

  def data_param(valor)
    Date.iso8601(valor.to_s) if valor.present?
  rescue Date::Error
    nil
  end
end
