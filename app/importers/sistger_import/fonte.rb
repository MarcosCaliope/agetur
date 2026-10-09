require "tiny_tds"

class SistgerImport
  # Read-only access to the SISTGER SQL Server (see Configuracao for where
  # the connection settings come from).
  class Fonte
    ConexaoFalhou = Class.new(SistgerImport::Erro)

    attr_reader :configuracao

    def initialize(configuracao = Configuracao.carregar)
      @configuracao = configuracao
    end

    def configurada?
      configuracao.configurada?
    end

    def descricao
      configuracao.descricao
    end

    # Rows as hashes. DATETIMEs come back as the naive wall-clock time.
    def linhas(sql)
      cliente.execute(sql).each(timezone: :utc, as: :hash).to_a
    rescue TinyTds::Error => e
      raise ConexaoFalhou, "Erro ao ler o SISTGER: #{e.message}"
    end

    # {total:, ultimo:}: row count and highest value of the key column.
    def resumo(tabela, coluna)
      linha = linhas("SELECT COUNT(*) AS total, MAX(#{coluna}) AS ultimo FROM #{tabela}").first
      { total: linha["total"], ultimo: linha["ultimo"] }
    end

    def fechar
      @cliente&.close
      @cliente = nil
    end

    private

    def cliente
      return @cliente if @cliente&.active?

      unless configurada?
        raise ConexaoFalhou, "Conexão com o SISTGER não configurada: defina SISTGER_DB_HOST ou o registro do Windows do SISTGER."
      end

      # The legacy SQL Server 2014 only offers TLS 1.0, which FreeTDS refuses;
      # this config turns TLS off for the connection (FreeTDS reads it per login).
      if ENV["SISTGER_DB_ENCRYPTION"] == "off"
        ENV["FREETDSCONF"] = Rails.root.join("config/freetds-sem-criptografia.conf").to_s
      end

      @cliente = TinyTds::Client.new(**configuracao.parametros_conexao, tds_version: "7.4", login_timeout: 10, timeout: 300)
    rescue TinyTds::Error => e
      raise ConexaoFalhou, "Não foi possível conectar ao SISTGER (#{descricao}): #{e.message}"
    end
  end
end
