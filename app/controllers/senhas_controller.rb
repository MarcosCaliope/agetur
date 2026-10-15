# "Minha senha": the signed-in account (admin or user) changes its own
# password, confirming the current one. Every account may, so it's left out
# of the route permissions (Permissao::LIVRES).
class SenhasController < ApplicationController
  skip_before_action :verificar_permissao!

  def edit
    @conta = conta
  end

  def update
    @conta = conta
    if @conta.update_with_password(params.require(:conta).permit(:current_password, :password, :password_confirmation))
      # Changing the password rotates the session; keep this one signed in.
      bypass_sign_in @conta, scope: admin_signed_in? ? :admin : :user
      redirect_to root_path, notice: "Senha alterada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def conta
    current_admin || current_user
  end
end
