# Manutenção > SISTGER > Excluir dados (admins only, Permissao::SO_ADMIN):
# deletes every record of the chosen tables in the company picked in the
# header, to clear it before importing again (see SistgerExclusao). Doesn't
# need the SISTGER connection, so it also works in production.
class SistgerExclusoesController < ApplicationController
  CONFIRMACAO = "EXCLUIR".freeze

  # GET /manutencao/sistger/exclusao(?etapas[]=...): the tables with their
  # counts; with etapas, the confirmation of what will be deleted.
  def index
    @empresa = empresa_atual
    return unless @empresa

    @contagens = SistgerExclusao.new(@empresa.id).contagens
    @escolhidas = SistgerExclusao::EXCLUSAO & Array(params[:etapas])
  end

  # DELETE /manutencao/sistger/exclusao with etapas[] and confirmacao
  def destroy
    empresa = empresa_atual or return redirect_to(sistger_exclusoes_path, alert: "Escolha a empresa.")
    chaves = Array(params[:etapas])
    unless params[:confirmacao].to_s.strip.upcase == CONFIRMACAO
      return redirect_to sistger_exclusoes_path(etapas: chaves), alert: "Digite #{CONFIRMACAO} para confirmar a exclusão."
    end

    resultados = SistgerExclusao.new(empresa.id).excluir(chaves)
    partes = resultados.map { |r| "#{r.etapa.nome}: #{r.excluidos}" }
    redirect_to sistger_exclusoes_path, notice: "Exclusão concluída em #{empresa.name}. #{partes.join('; ')}."
  rescue SistgerExclusao::Erro => e
    redirect_to sistger_exclusoes_path(etapas: chaves), alert: e.message
  end
end
