# The SISTGER import from the command line, for a database the web screen
# can't reach SQL Server from (production on Render: docs/deploy-render.md).
# Runs where SQL Server is reachable, against DATABASE_URL:
#
#   DATABASE_URL='<external URL>' bin/rails sistger:importar             # every step
#   DATABASE_URL='<external URL>' ETAPAS=ordens,caixa bin/rails sistger:importar
#   DATABASE_URL='<external URL>' ETAPAS=hoteis EMPRESA=3 bin/rails sistger:importar
#
# EMPRESA is the destination company's code in this app (default: the only
# company imported from SISTGER; required when there are several, since each
# may come from its own SISTGER base). Before writing, the task shows source,
# destination and steps, and asks for confirmation. CONFIRMAR=s skips the
# question (scripts).
namespace :sistger do
  desc "Importa do SISTGER todas as etapas (ou ETAPAS=a,b) para o banco da DATABASE_URL (EMPRESA=código do destino)"
  task importar: :environment do
    chaves = ENV["ETAPAS"].present? ? ENV["ETAPAS"].split(",").map(&:strip) : SistgerImport::ETAPAS.map(&:chave)
    chaves.each { |chave| SistgerImport.etapa(chave) } # unknown steps fail before anything is written
    empresa = nil
    if ENV["EMPRESA"].present?
      empresa = Company.unscoped.find_by(id: ENV["EMPRESA"]) or
        abort "Erro: empresa #{ENV['EMPRESA']} não existe. Empresas: " +
              Company.unscoped.order(:id).map { |c| "#{c.id} (#{c.name})" }.join(", ")
    end

    fonte = SistgerImport::Fonte.new
    importador = SistgerImport.new(fonte, empresa_id: empresa&.id)
    banco = ActiveRecord::Base.connection_db_config.configuration_hash.values_at(:host, :database).compact.join("/")
    destino = Company.unscoped.find_by(id: importador.empresa_destino_id)
    if destino.nil? && Company.unscoped.where.not(sistger_id: nil).exists?
      abort "Erro: há mais de uma empresa importada do SISTGER. Informe EMPRESA=<código>. Empresas: " +
            Company.unscoped.order(:id).map { |c| "#{c.id} (#{c.name})" }.join(", ")
    end
    puts "SISTGER: #{fonte.descricao}"
    puts "Destino: #{banco}"
    puts "Empresa: #{destino ? "#{destino.id} - #{destino.name}" : 'nova, criada pela etapa Empresa'}"
    puts "Etapas:  #{SistgerImport::ETAPAS.select { |e| chaves.include?(e.chave) }.map(&:nome).join(', ')}"

    unless ENV["CONFIRMAR"] == "s"
      print "Importar? (s/N) "
      abort "Importação cancelada." unless $stdin.gets.to_s.strip.downcase.start_with?("s")
    end

    importador.importar_etapas(chaves).each do |resultado|
      puts "#{resultado.etapa.nome}: #{resultado.lidos} lidos, #{resultado.gravados} gravados"
      resultado.avisos.each { |aviso| puts "  aviso: #{aviso}" }
    end
  rescue SistgerImport::Erro => e
    abort "Erro: #{e.message}"
  ensure
    fonte&.fechar
  end

  # Deletes every record of the chosen tables in one company (SistgerExclusao),
  # e.g. to import it again. Doesn't touch SISTGER.
  #
  #   DATABASE_URL='<external URL>' EMPRESA=3 ETAPAS=hoteis,ordens bin/rails sistger:excluir
  desc "Exclui todos os registros das ETAPAS=a,b na EMPRESA=código, no banco da DATABASE_URL"
  task excluir: :environment do
    etapas = SistgerExclusao::EXCLUSAO.join(",")
    abort "Informe ETAPAS=... (#{etapas})." if ENV["ETAPAS"].blank?
    empresas = -> { Company.unscoped.order(:id).map { |c| "#{c.id} (#{c.name})" }.join(", ") }
    abort "Informe EMPRESA=<código>. Empresas: #{empresas.call}" if ENV["EMPRESA"].blank?
    empresa = Company.unscoped.find_by(id: ENV["EMPRESA"]) or abort "Erro: empresa #{ENV['EMPRESA']} não existe. Empresas: #{empresas.call}"

    exclusao = SistgerExclusao.new(empresa.id)
    contagens = exclusao.contagens(ENV["ETAPAS"].split(",").map(&:strip))
    banco = ActiveRecord::Base.connection_db_config.configuration_hash.values_at(:host, :database).compact.join("/")
    puts "Banco:   #{banco}"
    puts "Empresa: #{empresa.id} - #{empresa.name}"
    puts "Serão excluídos TODOS os registros (importados ou não):"
    contagens.each { |chave, total| puts "  #{SistgerImport.etapa(chave).nome}: #{total}" }

    unless ENV["CONFIRMAR"] == "s"
      print "Digite EXCLUIR para confirmar: "
      abort "Exclusão cancelada." unless $stdin.gets.to_s.strip.upcase == "EXCLUIR"
    end

    exclusao.excluir(contagens.keys).each { |r| puts "#{r.etapa.nome}: #{r.excluidos} excluídos" }
  rescue SistgerExclusao::Erro => e
    abort "Erro: #{e.message} (nada foi excluído)"
  end
end
