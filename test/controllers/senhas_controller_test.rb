require 'test_helper'

class SenhasControllerTest < ActionDispatch::IntegrationTest
  def alterar(conta, atual:, nova: "novasenha", confirmacao: nova)
    patch minha_senha_url, params: { conta: { current_password: atual, password: nova, password_confirmation: confirmacao } }
  end

  test "a user without any route changes their password and stays signed in" do
    user = users(:sem_rotas)
    sign_in user
    get root_url
    assert_select "a[href='#{minha_senha_path}']", text: "Minha senha"

    get minha_senha_url
    assert_response :success
    alterar user, atual: "password"
    assert_redirected_to root_url
    assert user.reload.valid_password?("novasenha")

    get minha_senha_url
    assert_response :success
  end

  test "refuses a wrong current password" do
    user = users(:one)
    sign_in user
    alterar user, atual: "errada"
    assert_response :unprocessable_entity
    assert_select "#error_explanation li", text: /Senha atual/
    assert user.reload.valid_password?("password")
  end

  test "refuses a confirmation that doesn't match" do
    user = users(:one)
    sign_in user
    alterar user, atual: "password", confirmacao: "outra"
    assert_response :unprocessable_entity
    assert user.reload.valid_password?("password")
  end

  test "an admin changes their own password" do
    admin = admins(:one)
    sign_in admin
    get admins_backoffice_welcome_index_url
    assert_select "a[href='#{minha_senha_path}']"

    alterar admin, atual: "password"
    assert_redirected_to root_url
    assert admin.reload.valid_password?("novasenha")
  end

  test "requires sign-in" do
    get minha_senha_url
    assert_redirected_to new_user_session_url
  end
end
