# Acesso das empresas: an admin blocks a company's users by hand or lets
# their access run until a date (the monthly fee is paid through it, see
# Mensalidade), and sets what the company pays and when it's due. Kept
# out of CompaniesController, which users with acesso_total can open, so a
# company can't lift its own block. See Company#acesso_suspenso?.
class AdminsBackoffice::CompaniesController < AdminsBackofficeController
  before_action :set_company, only: %i[edit update]

  def index
    @companies = Company.order(:name)
    @usuarios = User.where(company_id: @companies.map(&:id)).group(:company_id).count
    @ultimas_pagas = Mensalidade.group(:company_id).maximum(:referencia)
  end

  def edit; end

  def update
    if @company.update(company_params)
      redirect_to admins_backoffice_companies_path, notice: "Acesso da empresa atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:acesso_bloqueado, :acesso_liberado_ate, :mensalidade_valor, :dia_vencimento, :dias_tolerancia)
  end
end
