# Usuários do sistema, created and kept by an admin (sign-up is closed). Each
# user's form lists every route of the system (Permissao.grupos) with a
# checkbox, and the user may open only the checked ones.
class AdminsBackoffice::UsersController < AdminsBackofficeController
  before_action :set_user, only: %i[edit update destroy]
  before_action :set_grupos, only: %i[new create edit update]

  def index
    @users = User.includes(:company).order(:email)
    @vendedores = Vendor.unscoped.where(id: @users.map(&:vendor_id).compact).index_by(&:id)
  end

  # ?copiar=ID starts from another user's routes.
  def new
    modelo = User.find_by(id: params[:copiar])
    @user = User.new(acesso_empresa: modelo&.acesso_empresa, acesso_total: modelo&.acesso_total || false, permissoes: modelo&.permissoes || [])
  end

  def edit; end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admins_backoffice_users_path, notice: "Usuário criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # A blank password keeps the current one.
  def update
    atributos = user_params
    atributos = atributos.except(:password, :password_confirmation) if atributos[:password].blank?
    if @user.update(atributos)
      redirect_to admins_backoffice_users_path, notice: "Usuário atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy!
    redirect_to admins_backoffice_users_path, notice: "Usuário excluído com sucesso."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_grupos
    @grupos = Permissao.grupos
    # Every company's vendors: a vendor login works in its vendor's company.
    @vendor_options = Vendor.unscoped.includes(:company).where(active: true).or(Vendor.unscoped.where(id: @user&.vendor_id))
                            .order(:sname).map { |vendedor| ["#{vendedor.sname} (#{vendedor.company&.name})", vendedor.id] }
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :acesso_empresa, :vendor_id, :acesso_total, permissoes: [])
  end
end
