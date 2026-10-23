# The SISTGER import from the command line, for a database the web screen
# can't reach SQL Server from (production on Render: docs/deploy-render.md).
# Runs where SQL Server is reachable, against DATABASE_URL:
#
#   DATABASE_URL='<external URL>' bin/rails sistger:importar             # every step
#   DATABASE_URL='<external URL>' ETAPAS=ordens,caixa bin/rails sistger:importar
namespace :sistger do
  desc "Importa do SISTGER todas as etapas (ou ETAPAS=a,b) para o banco da DATABASE_URL"
  task importar: :environment do
    fonte = SistgerImport::Fonte.new
    chaves = ENV["ETAPAS"].present? ? ENV["ETAPAS"].split(",").map(&:strip) : SistgerImport::ETAPAS.map(&:chave)
    chaves.each { |chave| SistgerImport.etapa(chave) } # unknown steps fail before anything is written
    banco = ActiveRecord::Base.connection_db_config.configuration_hash.values_at(:host, :database).compact.join("/")
    puts "SISTGER: #{fonte.descricao}"
    puts "Destino: #{banco}"

    SistgerImport.new(fonte).importar_etapas(chaves).each do |resultado|
      puts "#{resultado.etapa.nome}: #{resultado.lidos} lidos, #{resultado.gravados} gravados"
      resultado.avisos.each { |aviso| puts "  aviso: #{aviso}" }
    end
  rescue SistgerImport::Erro => e
    abort "Erro: #{e.message}"
  ensure
    fonte&.fechar
  end
end
