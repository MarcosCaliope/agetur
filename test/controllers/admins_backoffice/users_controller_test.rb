require 'test_helper'

class AdminsBackoffice::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
  end

  test "lists users with their access" do
    get admins_backoffice_users_url
    assert_response :success
    assert_select "td", text: users(:consulta).email
    assert_select "td", text: "5 rotas liberadas"
    assert_select "td", text: "Total"
    assert_select "td span.text-danger", text: /Nenhuma rota/
  end

  test "the form lists every route with a checkbox" do
    get edit_admins_backoffice_user_url(users(:consulta))
    assert_response :success
    assert_select "input[type=checkbox][name='user[permissoes][]']", count: Permissao.chaves.size
    assert_select "input[type=checkbox][value='sorders#index'][checked]"
    assert_select "input[type=checkbox][value='sorders#destroy']:not([checked])"
    assert_select "code", text: "DELETE /sorders/:id"
  end

  test "creates a user with its routes" do
    get new_admins_backoffice_user_url
    assert_response :success
    assert_difference("User.count") do
      post admins_backoffice_users_url, params: { user: { name: "Maria", email: "maria@example.com", password: "senha123",
                                                         password_confirmation: "senha123", permissoes: ["", "cash_entries#index", "payables#pagar"] } }
    end
    assert_redirected_to admins_backoffice_users_url
    user = User.find_by!(email: "maria@example.com")
    assert_equal %w[cash_entries#index payables#pagar], user.permissoes
    assert_not user.acesso_total?
    assert user.valid_password?("senha123")
  end

  test "copiar starts from another user's routes" do
    get new_admins_backoffice_user_url(copiar: users(:consulta).id)
    assert_response :success
    assert_select "input[type=checkbox][value='sorders#index'][checked]"
    assert_select "input[type=checkbox][value='sorders#destroy']:not([checked])"
  end

  test "rejects an invalid user" do
    assert_no_difference("User.count") do
      post admins_backoffice_users_url, params: { user: { email: "", password: "1" } }
    end
    assert_response :unprocessable_entity
  end

  test "a blank password keeps the current one" do
    user = users(:consulta)
    patch admins_backoffice_user_url(user), params: { user: { name: "Outro", password: "", password_confirmation: "", permissoes: ["", "hotels#index"] } }
    assert_redirected_to admins_backoffice_users_url
    user.reload
    assert_equal "Outro", user.name
    assert_equal ["hotels#index"], user.permissoes
    assert user.valid_password?("password")
  end

  test "unchecking everything clears the routes" do
    patch admins_backoffice_user_url(users(:consulta)), params: { user: { permissoes: [""] } }
    assert_empty users(:consulta).reload.permissoes
  end

  test "changes the password" do
    patch admins_backoffice_user_url(users(:one)), params: { user: { password: "nova1234", password_confirmation: "nova1234" } }
    assert users(:one).reload.valid_password?("nova1234")
  end

  test "destroys a user" do
    assert_difference("User.count", -1) do
      delete admins_backoffice_user_url(users(:one))
    end
    assert_redirected_to admins_backoffice_users_url
  end

  test "users can't manage users" do
    sign_out :admin
    sign_in users(:one)
    get admins_backoffice_users_url
    assert_redirected_to new_admin_session_url
    assert_no_difference("User.count") do
      post admins_backoffice_users_url, params: { user: { email: "x@example.com", password: "senha123", password_confirmation: "senha123" } }
    end
  end
end
