# The company an admin, or a user with todas_empresas, works in
# (Current.empresa_id): picked in the header, kept in the session. Not a
# screen, so it's left out of the route permissions (Permissao::LIVRES).
class TrocaEmpresaController < ApplicationController
  skip_before_action :verificar_permissao!

  def update
    unless escolhe_empresa?
      redirect_to root_path, alert: "Seu cadastro não permite trocar de empresa."
      return
    end

    empresa = Company.find(params[:empresa_id])
    session[:empresa_id] = empresa.id
    redirect_back fallback_location: root_path, notice: "Trabalhando agora na empresa #{empresa.name}."
  end
end
