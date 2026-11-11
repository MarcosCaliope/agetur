require 'test_helper'

class AdminsBackoffice::MensalidadesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
    @company = companies(:two)
    @company.update!(mensalidade_valor: 150, dia_vencimento: 10, dias_tolerancia: 5)
  end

  test "the month lists billed companies, paid or open" do
    companies(:one).update!(mensalidade_valor: 90, dia_vencimento: 5)
    @company.mensalidades.create!(referencia: Date.new(2026, 11, 1), valor: 150, pago_em: Date.new(2026, 11, 9), forma: "PIX")

    get admins_backoffice_mensalidades_url(mes: "2026-11")
    assert_response :success
    assert_select "h1", text: /Novembro\/2026/
    assert_select "span.badge-success", text: "Paga", count: 1
    assert_select "a[title='Registrar pagamento'] i.fa-money", count: 1
    assert_select "tfoot td", text: /R\$ 240,00/
  end

  test "registers a payment and frees access" do
    get new_admins_backoffice_company_mensalidade_url(@company, referencia: "2026-11", retorno: "mes")
    assert_response :success
    assert_select "input[name='mensalidade[referencia]'][value='2026-11']"
    assert_select "input[name='mensalidade[valor]'][value='150.0']"

    assert_difference("Mensalidade.count") do
      post admins_backoffice_company_mensalidades_url(@company),
           params: { retorno: "mes", mensalidade: { referencia: "2026-11", valor: "150.00", pago_em: "2026-11-09", forma: "PIX" } }
    end
    assert_redirected_to admins_backoffice_mensalidades_url(mes: "2026-11")
    mensalidade = Mensalidade.last
    assert_equal Date.new(2026, 11, 1), mensalidade.referencia
    assert_equal admins(:one).email, mensalidade.registrado_por
    assert_equal Date.new(2026, 12, 15), @company.reload.acesso_liberado_ate
  end

  test "lists and deletes a company's payments" do
    mensalidade = @company.mensalidades.create!(referencia: Date.new(2026, 11, 1), valor: 150, pago_em: Date.current)
    get admins_backoffice_company_mensalidades_url(@company)
    assert_response :success
    assert_select "td", text: "Novembro/2026"

    assert_difference("Mensalidade.count", -1) do
      delete admins_backoffice_company_mensalidade_url(@company, mensalidade)
    end
    assert_redirected_to admins_backoffice_company_mensalidades_url(@company)
  end

  test "the access screen sets what the company pays" do
    patch admins_backoffice_company_url(companies(:one)), params: { company: { mensalidade_valor: "99.90", dia_vencimento: "5", dias_tolerancia: "3" } }
    assert_redirected_to admins_backoffice_companies_url
    companies(:one).reload
    assert_equal 99.9.to_d, companies(:one).mensalidade_valor
    assert_equal [5, 3], [companies(:one).dia_vencimento, companies(:one).dias_tolerancia]
  end

  test "users can't open it" do
    sign_out :admin
    sign_in users(:one)
    get admins_backoffice_mensalidades_url
    assert_redirected_to new_admin_session_path
  end
end
