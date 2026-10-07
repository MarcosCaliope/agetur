require 'test_helper'

class SistgerImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @fonte = SistgerFonteFalsa.new(
      "tblClientes" => [10, 20, 30].map do |codigo|
        { "iCodigo" => codigo, "snome" => "CLIENTE #{codigo}", "scgc" => nil, "stelefone" => nil, "sfone2" => nil, "semail" => nil,
          "sendereco" => nil, "sBairro" => nil, "scidade" => nil, "sestado" => nil, "scontato" => nil }
      end
    )
    def @fonte.configurada? = true
    def @fonte.descricao = "servidor de teste"
  end

  def com_fonte(fonte = @fonte, &bloco)
    SistgerImport::Fonte.stub(:new, fonte, &bloco)
  end

  test "requires login" do
    sign_out :user
    get sistger_imports_url
    assert_redirected_to new_user_session_path
  end

  test "index lists every step with checkbox, counts and filters" do
    com_fonte { get sistger_imports_url }
    assert_response :success
    assert_select "tbody tr.sistger-etapa", SistgerImport::ETAPAS.size
    assert_select "tr[data-etapa=clientes]" do
      assert_select "input[type=checkbox][name='etapas[]'][value=clientes]"
      assert_select "td.text-right", text: "3"
      assert_select "td.sistger-ultimo", text: "30"
      assert_select "td.sistger-ultimo-importado", text: "—"
      assert_select "select[name='filtros[clientes][modo]'] option", text: /Todos|Faixa de código|Últimos registros/, count: 3
      assert_select "input[name='filtros[clientes][inicio]']", count: 0
    end
    assert_select "tr[data-etapa=ordens] select option[value=periodo]", text: "Período"
    assert_select "tr[data-etapa=ordens] input[type=date][name='filtros[ordens][inicio]']"
    assert_select "input[type=submit][value=?]", "Importar selecionadas"
  end

  test "index explains when the connection isn't configured" do
    def @fonte.configurada? = false
    com_fonte { get sistger_imports_url }
    assert_select ".alert-warning", text: /registro do Windows/
  end

  test "index shows connection errors" do
    def @fonte.resumo(*, **) = raise(SistgerImport::Fonte::ConexaoFalhou, "Não foi possível conectar ao SISTGER")
    com_fonte { get sistger_imports_url }
    assert_select ".alert-danger", text: /Não foi possível conectar/
  end

  test "preview applies the row's filter" do
    com_fonte { get sistger_import_url("clientes", filtros: { clientes: { modo: "faixa", de: 20, ate: 20 } }) }
    assert_response :success
    assert_select "p", text: /códigos 20 a 20/
    assert_select "th", text: "Código SISTGER"
    assert_select "td", text: "CLIENTE 20"
    assert_select "td", text: "CLIENTE 10", count: 0
  end

  test "imports only the selected steps with their filters" do
    assert_difference("Customer.count", 2) do
      com_fonte do
        post sistger_imports_url, params: { etapas: ["clientes"], filtros: { clientes: { modo: "ultimos", quantidade: 2 },
                                                                         hoteis: { modo: "todos" } } }
      end
    end
    assert_equal [20, 30], Customer.where.not(sistger_id: nil).order(:sistger_id).pluck(:sistger_id)
    follow_redirect!
    assert_select ".alert-success", text: /Clientes \(últimos 2\): 2 de 2 gravados/
    com_fonte { get sistger_imports_url }
    assert_select "tr[data-etapa=clientes] td.sistger-ultimo-importado", text: "30"
  end

  test "asks to select at least one step" do
    com_fonte { post sistger_imports_url }
    follow_redirect!
    assert_select ".alert-danger", text: "Selecione ao menos uma tabela para importar."
  end

  test "reports invalid filters and dependency errors" do
    com_fonte { post sistger_imports_url, params: { etapas: ["clientes"], filtros: { clientes: { modo: "faixa" } } } }
    follow_redirect!
    assert_select ".alert-danger", text: "Clientes: Informe o código inicial e/ou final da faixa."

    com_fonte { post sistger_imports_url, params: { etapas: ["ordens"] } }
    follow_redirect!
    assert_select ".alert-danger", text: "Importe empresa antes de ordens de serviço."
  end

  test "unknown steps are not found" do
    com_fonte { get sistger_import_url("nada") }
    assert_response :not_found
    sign_in users(:one) # the 404 response doesn't write the session cookie back
    com_fonte { post sistger_imports_url, params: { etapas: ["nada"] } }
    assert_response :not_found
  end

  test "dashboard has the Manutenção tab linking to the import" do
    get root_url
    assert_select ".dashboard-tabs a[href='#manutencao']", text: "Manutenção"
    assert_select "#manutencao a[href=?]", sistger_imports_path
  end
end
