class ApplicationController < ActionController::Base
  # Every page requires a signed-in User or Admin unless its controller opts
  # out: Devise's own controllers, the public site and the namespaced
  # back-offices (which run their own authenticate_user!/authenticate_admin!).
  before_action :authenticate_user_or_admin!, unless: :devise_controller?
  # A User may only open the routes checked in their cadastro; admins open all.
  # The controllers that opt out of this are Permissao::LIVRES.
  before_action :verificar_permissao!, unless: :devise_controller?

  helper_method :pode_acessar?

  private

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
