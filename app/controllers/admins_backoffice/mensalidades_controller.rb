# Mensalidades das empresas (admins only): the month's overview (who paid,
# who's open or late), each company's payment history, and registering or
# deleting a payment, which moves the company's access date (Mensalidade).
class AdminsBackoffice::MensalidadesController < AdminsBackofficeController
  before_action :set_company, except: :mes

  def mes
    @mes = mes_param(params[:mes]) || Date.current.beginning_of_month
    @companies = Company.order(:name).select(&:cobrada?)
    @pagas = Mensalidade.where(referencia: @mes).index_by(&:company_id)
  end

  def index
    @mensalidades = @company.mensalidades.recentes
  end

  def new
    @mensalidade = @company.mensalidades.new(referencia: mes_param(params[:referencia]) || @company.proxima_referencia,
                                             valor: @company.mensalidade_valor, pago_em: Date.current)
  end

  def create
    @mensalidade = @company.mensalidades.new(mensalidade_params.merge(registrado_por: current_admin.email))
    if @mensalidade.save
      @company.reload
      aviso = "Pagamento de #{I18n.l(@mensalidade.referencia, format: "%B/%Y")} registrado. Acesso liberado até #{I18n.l(@company.acesso_liberado_ate)}."
      aviso += " A empresa continua com o bloqueio manual marcado." if @company.acesso_bloqueado?
      redirect_to retorno(@mensalidade.referencia), notice: aviso
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    mensalidade = @company.mensalidades.find(params[:id])
    mensalidade.destroy!
    @company.reload
    liberado = @company.acesso_liberado_ate ? "Acesso liberado até #{I18n.l(@company.acesso_liberado_ate)}." : "Sem data limite de acesso."
    redirect_to admins_backoffice_company_mensalidades_path(@company),
                notice: "Pagamento de #{I18n.l(mensalidade.referencia, format: "%B/%Y")} excluído. #{liberado}"
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  # A month field sends "2026-11".
  def mes_param(valor)
    Date.strptime(valor.to_s, "%Y-%m") if valor.to_s.match?(/\A\d{4}-\d{2}/)
  rescue Date::Error
    nil
  end

  def mensalidade_params
    atributos = params.require(:mensalidade).permit(:referencia, :valor, :pago_em, :forma, :observacao)
    atributos.merge(referencia: mes_param(atributos[:referencia]))
  end

  def retorno(referencia)
    if params[:retorno] == "mes"
      admins_backoffice_mensalidades_path(mes: referencia.strftime("%Y-%m"))
    else
      admins_backoffice_company_mensalidades_path(@company)
    end
  end
end
