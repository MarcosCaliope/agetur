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
end
