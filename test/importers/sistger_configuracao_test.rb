require 'test_helper'

class SistgerConfiguracaoTest < ActiveSupport::TestCase
  REGISTRO = { "DATA_SOURCE" => "mynt\\sqlexpress", "INITIAL_CATALOG" => "sistger", "USER_ID" => "sa", "PASSWORD" => "segredo" }.freeze

  def carregar(env, registro = REGISTRO)
    SistgerImport::Configuracao.carregar(env: env, registro: registro)
  end

  test "uses the Windows registry when no variables are set" do
    config = carregar({})
    assert config.configurada?
    assert_equal({ database: "sistger", username: "sa", password: "segredo", dataserver: "mynt\\sqlexpress" }, config.parametros_conexao)
    assert_equal "mynt\\sqlexpress, banco sistger (registro do Windows)", config.descricao
  end

  test "variables override the registry, and host/port skip the named instance" do
    config = carregar("SISTGER_DB_HOST" => "172.24.0.1", "SISTGER_DB_PORT" => "51027")
    assert_equal({ database: "sistger", username: "sa", password: "segredo", host: "172.24.0.1", port: 51027 }, config.parametros_conexao)
    assert_equal({ host: :env, banco: :registro, usuario: :registro, senha: :registro }, config.origens)

    vazia = carregar("SISTGER_DB_PASSWORD" => "", "SISTGER_DB_USERNAME" => "leitor")
    assert_equal ["leitor", ""], vazia.parametros_conexao.values_at(:username, :password)
  end

  test "not configured without a host from either source" do
    config = carregar({}, {})
    assert_not config.configurada?
    assert_equal "sistger", config.banco
  end

  test "parses reg.exe output, including empty values" do
    saida = "\r\nHKEY_CURRENT_USER\\SOFTWARE\\VB and VBA Program Settings\\oServico\\BANCO_DE_DADOS\r\n" \
            "    DATA_SOURCE    REG_SZ    mynt\\sqlexpress\r\n    PASSWORD    REG_SZ    \r\n    USER_ID    REG_SZ    sa\r\n\r\n"
    status = Struct.new(:success?).new(true)
    File.stub(:exist?, true) do
      Open3.stub(:capture2e, [saida, status]) do
        assert_equal({ "DATA_SOURCE" => "mynt\\sqlexpress", "PASSWORD" => "", "USER_ID" => "sa" },
                     SistgerImport::Configuracao.ler_registro({}))
      end
    end
    assert_equal({}, SistgerImport::Configuracao.ler_registro("SISTGER_DB_REGISTRO" => "off"))
  end
end
