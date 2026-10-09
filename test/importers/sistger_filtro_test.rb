require 'test_helper'

class SistgerFiltroTest < ActiveSupport::TestCase
  Filtro = SistgerImport::Filtro

  def ordens = SistgerImport.etapa("ordens")
  def clientes = SistgerImport.etapa("clientes")

  test "todos reads the whole table in code order" do
    assert_match(/FROM tblClientes ORDER BY iCodigo\z/, Filtro.todos.sql(clientes))
    assert_match(/\ASELECT TOP 5 /, Filtro.todos.sql(clientes, limite: 5))
  end

  test "period filters orders by date, inclusive" do
    filtro = Filtro.de_params(modo: "periodo", inicio: "2026-06-01", fim: "2026-06-30")
    assert_match "WHERE Data >= '20260601' AND Data < '20260701'", filtro.sql(ordens)
    assert_equal "período 01/06/2026 a 30/06/2026", filtro.descricao
    assert_match "WHERE Data >= '20260601' ORDER", Filtro.de_params(modo: "periodo", inicio: "2026-06-01").sql(ordens)
  end

  test "period is only for orders" do
    filtro = Filtro.de_params(modo: "periodo", inicio: "2026-06-01")
    erro = assert_raises(SistgerImport::Erro) { filtro.sql(clientes) }
    assert_match "filtro por período não disponível", erro.message
  end

  test "code range uses each step's key column" do
    filtro = Filtro.de_params(modo: "faixa", de: "100", ate: "200")
    assert_match "FROM tblClientes WHERE iCodigo >= 100 AND iCodigo <= 200", filtro.sql(clientes)
    assert_match "FROM tblOrdemServico WHERE iNumero >= 100 AND iNumero <= 200 ORDER BY iNumero", filtro.sql(ordens)
    assert_match "WHERE iCodigo <= 50 ORDER", Filtro.de_params(modo: "faixa", ate: "50").sql(clientes)
  end

  test "last N takes the highest codes" do
    filtro = Filtro.de_params(modo: "ultimos", quantidade: "10")
    assert_match(/\ASELECT TOP 10 .* FROM tblClientes ORDER BY iCodigo DESC\z/, filtro.sql(clientes))
    assert_match(/\ASELECT TOP 5 /, filtro.sql(clientes, limite: 5))
    assert_match(/\ASELECT TOP 10 .* FROM tblOrdemServico ORDER BY iNumero DESC\z/, filtro.sql(ordens))
  end

  test "rejects incomplete or invalid filters" do
    {
      { modo: "periodo" } => "Informe a data inicial",
      { modo: "periodo", inicio: "2026-02-01", fim: "2026-01-01" } => "posterior",
      { modo: "periodo", inicio: "31/12/2026" } => "Data inicial inválida",
      { modo: "faixa" } => "Informe o código",
      { modo: "faixa", de: "9", ate: "1" } => "maior que o final",
      { modo: "faixa", de: "1; DROP TABLE x" } => "Código inicial inválido",
      { modo: "ultimos", quantidade: "0" } => "Informe quantos",
      { modo: "outro" } => "Filtro desconhecido"
    }.each do |params, mensagem|
      erro = assert_raises(SistgerImport::Erro, params.inspect) { Filtro.de_params(params) }
      assert_match mensagem, erro.message
    end
  end
end
