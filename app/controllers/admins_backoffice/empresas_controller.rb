# The company an admin works in (Current.empresa_id): picked in the header,
# kept in the session.
class AdminsBackoffice::EmpresasController < AdminsBackofficeController
  def update
    empresa = Company.find(params[:empresa_id])
    session[:empresa_id] = empresa.id
    redirect_back fallback_location: root_path, notice: "Trabalhando agora na empresa #{empresa.name}."
  end
end
