# Manutenção > Importar do SISTGER: reads the legacy SQL Server and imports
# the chosen steps, each with its own filter (see SistgerImport::Filtro),
# into the company picked in the header (empresa_atual). Records already
# imported into another company move to it; the index warns how many.
class SistgerImportsController < ApplicationController
  # GET /manutencao/sistger
  def index
    @configurada = fonte.configurada?
    return unless @configurada

    @contagens = importador.contagens
    @em_outras_empresas = importador.importados_em_outras_empresas(SistgerImport::ETAPAS.map(&:chave))
  rescue SistgerImport::Erro => e
    @erro = e.message
  ensure
    fonte.fechar
  end

  # GET /manutencao/sistger/:etapa?filtros[:etapa][modo]=... (preview)
  def show
    @etapa = etapa(params[:etapa])
    @filtro = filtro(@etapa.chave)
    @linhas = importador.previa(@etapa.chave, @filtro)
  rescue SistgerImport::Erro => e
    redirect_to sistger_imports_path, alert: e.message
  ensure
    fonte.fechar
  end

  # POST /manutencao/sistger with etapas[] and filtros[etapa][...]
  def create
    chaves = Array(params[:etapas]).map { |chave| etapa(chave).chave }
    return redirect_to(sistger_imports_path, alert: "Selecione ao menos uma tabela para importar.") if chaves.empty?

    filtros = chaves.index_with { |chave| filtro(chave) }
    redirect_to sistger_imports_path, notice: resumo(importador.importar_etapas(chaves, filtros))
  rescue SistgerImport::Erro => e
    redirect_to sistger_imports_path, alert: e.message
  ensure
    fonte.fechar
  end

  private

  def etapa(chave)
    SistgerImport.etapa(chave)
  rescue SistgerImport::Erro
    raise ActionController::RoutingError, "Etapa desconhecida"
  end

  def filtro(chave)
    valores = params.dig(:filtros, chave)&.permit(:modo, :inicio, :fim, :de, :ate, :quantidade)
    SistgerImport::Filtro.de_params(valores)
  rescue SistgerImport::Erro => e
    raise SistgerImport::Erro, "#{SistgerImport.etapa(chave).nome}: #{e.message}"
  end

  def fonte
    @fonte ||= SistgerImport::Fonte.new
  end
  helper_method :fonte

  def importador
    @importador ||= SistgerImport.new(fonte, empresa_id: empresa_atual&.id)
  end

  def resumo(resultados)
    partes = resultados.map do |r|
      com = " (com #{r.detalhes.to_sentence})" if r.detalhes.present?
      "#{r.etapa.nome} (#{r.filtro.descricao}): #{r.gravados} de #{r.lidos} gravados#{com}"
    end
    avisos = resultados.flat_map(&:avisos)
    (["Importação concluída em #{empresa_atual&.name}. #{partes.join('; ')}."] + avisos).join(" ")
  end
end
