require 'test_helper'

# A User only opens the routes checked in their cadastro; admins open everything.
class PermissoesTest < ActionDispatch::IntegrationTest
  test "a restricted user opens the allowed routes" do
    sign_in users(:consulta)
    get sorders_url
    assert_response :success
    get sorder_url(sorders(:one))
    assert_response :success
    get edit_customer_url(customers(:one))
    assert_response :success
  end

  test "other routes go back to the home page" do
    sign_in users(:consulta)
    get hotels_url
    assert_redirected_to root_url
    follow_redirect!
    assert_select ".alert-danger", text: "Seu perfil não tem acesso a esta página."

    assert_no_difference("Sorder.count") do
      delete sorder_url(sorders(:one))
    end
    assert_redirected_to root_url
  end

  test "pdf and json answer forbidden" do
    sign_in users(:consulta)
    get hotels_url(format: :pdf)
    assert_response :forbidden
    get vehicles_url(format: :json)
    assert_response :forbidden
  end

  test "the home page only shows what the user may open" do
    sign_in users(:consulta)
    get root_url
    assert_response :success
    assert_select "a.nav-link", text: "Processos"
    assert_select "a.nav-link", text: "Cadastros"
    assert_select "a[href=?]", customers_path
    assert_select "a[href=?]", new_customer_path, count: 0
    assert_select "a.nav-link", text: "Manutenção", count: 0
    assert_select "a[href=?]", sorders_path
    assert_select "a[href=?]", new_sorder_path, count: 0
    assert_select "a[href=?]", cash_entries_path, count: 0
    assert_select "#cadastros.active"
  end

  test "a user without routes only sees the home page" do
    sign_in users(:sem_rotas)
    get root_url
    assert_response :success
    assert_select ".alert-info", text: /não libera nenhuma tela/
    assert_select "a.nav-link", count: 0
    get states_url
    assert_redirected_to root_url
  end

  test "screens only show links to allowed routes" do
    sign_in users(:consulta)
    get sorders_url
    assert_select "a[href=?]", sorder_path(sorders(:one))
    assert_select "a[href=?]", edit_sorder_path(sorders(:one)), count: 0
    assert_select "a[href=?][data-method=delete]", sorder_path(sorders(:one)), count: 0
    assert_select "a[href=?]", new_sorder_path, count: 0

    get customers_url
    assert_select "a[href=?]", edit_customer_path(customers(:one))
    assert_select "a[href=?][data-method=delete]", customer_path(customers(:one)), count: 0
  end

  test "users with acesso total and admins see every link" do
    [users(:one), admins(:one)].each do |conta|
      sign_in conta
      get sorders_url
      assert_select "a[href=?]", edit_sorder_path(sorders(:one))
      assert_select "a[href=?][data-method=delete]", sorder_path(sorders(:one))
      sign_out conta
    end
  end

  test "admins are not bound by the routes" do
    sign_in admins(:one)
    get sistger_imports_url
    assert_response :success
    get root_url
    assert_select "a[href=?]", admins_backoffice_welcome_index_path, text: "Administração"
  end
end
