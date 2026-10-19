# Agendamentos por usuário (SISTGER's "Passeios Agendados por Usuário",
# frmRelAgendamporusuario, which read the tblOrdemServicoItensLog inserts):
# the passengers placed in the period's orders, grouped by the account that
# placed them (SorderItem#usuario). Passengers from before that was recorded
# have no user; they're only counted. The record date is the booking's,
# when the passenger came from one, else the passenger's.
class AgendamentosPorUsuario
  attr_reader :inicio, :fim, :usuario

  def initialize(params)
    hoje = Time.zone.today
    @inicio = data_param(params[:inicio]) || hoje.beginning_of_month
    @fim = data_param(params[:fim]) || hoje
    @usuario = params[:usuario].presence
    @cancelados = params[:cancelados] == "1"
  end

  def cancelados? = @cancelados

  def itens
    @itens ||= begin
      escopo = do_periodo.where.not(usuario: [nil, ""])
      escopo = escopo.where(usuario: usuario) if usuario
      escopo.includes(:hotel, booking_item: :booking, sorder: :destination)
        .order(:usuario, "sorders.data", :sorder_id, :sistger_sequencial, :id).to_a
    end
  end

  # [[user, items]], by user.
  def grupos = itens.group_by(&:usuario).to_a

  def sem_usuario = usuario ? 0 : do_periodo.where(usuario: [nil, ""]).count

  def usuarios
    SorderItem.where.not(usuario: [nil, ""]).distinct.order(:usuario).pluck(:usuario)
  end

  def self.gravado_em(item)
    (item.booking_item&.booking || item).created_at.to_date
  end

  def titulo
    "Passeios agendados por usuário de #{I18n.l(inicio)} a #{I18n.l(fim)}"
  end

  def params_url
    { inicio: inicio, fim: fim, usuario: usuario, cancelados: ("1" if cancelados?) }.compact
  end

  private

  def do_periodo
    escopo = SorderItem.joins(:sorder).where(sorders: { data: inicio.beginning_of_day..fim.end_of_day })
    cancelados? ? escopo : escopo.ativos
  end

  def data_param(valor)
    Date.iso8601(valor.to_s) if valor.present?
  rescue Date::Error
    nil
  end
end
