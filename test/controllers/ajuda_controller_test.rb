require "test_helper"

class AjudaControllerTest < ActionDispatch::IntegrationTest
  test "every signed-in account reads the manual, linked from the home page and the vendor's screens" do
    sign_in users(:sem_rotas)
    get root_url
    assert_select "a[href=?]", ajuda_path, text: "Ajuda"

    get ajuda_url
    assert_response :success
    assert_select "h1", "Manual de utilização"
    assert_select "nav.ajuda-indice a[href='#transferir']", "Transferir e copiar passageiros"
    assert_select "section#comissoes h2", "Comissões"
  end

  test "a vendor login opens it from Minhas vendas" do
    vendedor = users(:sem_rotas)
    vendedor.update!(vendor: vendors(:one))
    sign_in vendedor
    get vendas_url
    assert_select "a[href=?]", ajuda_path(anchor: "vendas")
    get ajuda_url
    assert_response :success
  end

  test "it isn't a route to grant in the user's permissions" do
    assert_not Permissao.controlado?("ajuda")
    assert_not_includes Permissao.chaves, "ajuda#index"
  end

  test "logged out, it asks for the sign-in" do
    get ajuda_url
    assert_redirected_to new_user_session_url
  end
  test "each screen's Ajuda link opens the manual at that screen's section" do
    sign_in users(:one)
    {
      bookings_url => "agendamentos", sorders_url => "ordens", edit_sorder_url(sorders(:two)) => "ordens",
      movimentar_sorder_item_url(sorder_items(:one)) => "transferir",
      sorder_item_recebimentos_url(sorder_items(:one)) => "recebimentos", pagamento_comissoes_url => "comissoes",
      payables_url => "contas", cash_entries_url => "caixa", relacao_ordens_url => "relatorios",
      conferencia_sinais_url => "sinais", pickup_times_url => "configuracoes"
    }.each do |url, secao|
      get url
      assert_select "nav a[href=?][title='Ajuda sobre esta tela']", ajuda_path(anchor: secao), { text: "Ajuda" }, url
      assert_select "section##{secao}", 0, "the section is in the manual, not in #{url}"
    end

    get customers_url
    assert_select "nav a[href=?]", ajuda_path, text: "Ajuda"

    get ajuda_url
    ApplicationHelper::SECOES_DA_AJUDA.values.uniq.each { |secao| assert_select "section##{secao}", 1, secao }
    assert_select "nav a[title='Ajuda sobre esta tela']", 0
  end

  test "the admin screens have it too" do
    sign_in admins(:one)
    get admins_backoffice_users_url
    assert_select "nav a[href=?]", ajuda_path(anchor: "acesso"), text: "Ajuda"
  end
end
