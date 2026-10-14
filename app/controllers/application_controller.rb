class ApplicationController < ActionController::Base
  # Which company's data the request sees (see DaEmpresa). Runs first and is
  # never skipped, so every controller is scoped.
  prepend_before_action :definir_empresa
  # Every page requires a signed-in User or Admin unless its controller opts
  # out: Devise's own controllers, the public site and the namespaced
  # back-offices (which run their own authenticate_user!/authenticate_admin!).
  before_action :authenticate_user_or_admin!, unless: :devise_controller?
  # A User may only open the routes checked in their cadastro; admins open all.
  # The controllers that opt out of this are Permissao::LIVRES.
  before_action :verificar_permissao!, unless: :devise_controller?

  helper_method :pode_acessar?, :empresa_atual

  private

  # A user works in their company; an admin in the one picked in the header
  # (session[:empresa_id]), else the first.
  def definir_empresa
    if admin_signed_in?
      Current.empresa_id = Company.where(id: session[:empresa_id]).pick(:id) || Company.order(:id).pick(:id)
      Current.filtrar_empresa = true
    elsif user_signed_in?
      Current.empresa_id = current_user.company_id
      Current.filtrar_empresa = true
      Current.so_a_propria_empresa = true
    end
  end

  def empresa_atual
    return @empresa_atual if defined?(@empresa_atual)

    @empresa_atual = Current.empresa_id && Company.find_by(id: Current.empresa_id)
  end

  def authenticate_user_or_admin!
    authenticate_user! unless admin_signed_in?
  end

  def pode_acessar?(controller, action = "index")
    admin_signed_in? || (user_signed_in? && current_user.pode?(controller.to_s, action.to_s))
  end

  def verificar_permissao!
    return if pode_acessar?(controller_path, action_name)

    respond_to do |format|
      format.html { redirect_to root_path, alert: "Seu perfil não tem acesso a esta página." }
      format.any { head :forbidden }
    end
  end

  # Who did it, for records that keep it (SISTGER's sUsuario).
  def usuario_atual
    (current_admin || current_user)&.email
  end
end
