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
    assert_equal({ host: :env, porta: :env, banco: :registro, usuario: :registro, senha: :registro }, config.origens)

    vazia = carregar("SISTGER_DB_PASSWORD" => "", "SISTGER_DB_USERNAME" => "leitor")
    assert_equal ["leitor", ""], vazia.parametros_conexao.values_at(:username, :password)
  end

  test "the named instance's port from the registry follows the base SISTGER points at" do
    registro = REGISTRO.merge("DATA_SOURCE" => "mynt\\sqlexpress01", "PORTA_INSTANCIA" => "57003")
    config = carregar({ "SISTGER_DB_HOST" => "172.24.0.1" }, registro)
    assert_equal({ database: "sistger", username: "sa", password: "segredo", host: "172.24.0.1", port: 57003 }, config.parametros_conexao)
    assert_equal "172.24.0.1:57003, banco sistger (instância sqlexpress01, registro do Windows)", config.descricao

    forcada = carregar({ "SISTGER_DB_HOST" => "172.24.0.1", "SISTGER_DB_PORT" => "55960" }, registro)
    assert_equal 55960, forcada.porta, "SISTGER_DB_PORT still wins"
  end

  test "reads the instance's port from SQL Server's registry keys, fixed before dynamic" do
    status = Struct.new(:success?).new(true)
    saidas = {
      'HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\Instance Names\\SQL' =>
        "    SQLEXPRESS    REG_SZ    MSSQL12.SQLEXPRESS\r\n    SQLEXPRESS01    REG_SZ    MSSQL13.SQLEXPRESS01\r\n",
      'HKLM\\SOFTWARE\\Microsoft\\Microsoft SQL Server\\MSSQL13.SQLEXPRESS01\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll' =>
        "    TcpPort    REG_SZ    \r\n    TcpDynamicPorts    REG_SZ    57003\r\n"
    }
    Open3.stub(:capture2e, ->(_reg, _query, chave) { [saidas.fetch(chave, ""), status] }) do
      assert_equal "57003", SistgerImport::Configuracao.porta_da_instancia("reg.exe", "sqlexpress01")
      assert_nil SistgerImport::Configuracao.porta_da_instancia("reg.exe", "sqlexpress9")
    end
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
