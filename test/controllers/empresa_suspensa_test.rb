require 'test_helper'

# A company blocked or past its paid-through date (Company#acesso_suspenso?)
# keeps its own users out; admins and "todas as empresas" users still work.
class EmpresaSuspensaTest < ActionDispatch::IntegrationTest
  MENSAGEM = "O acesso da sua empresa ao sistema está suspenso"

  test "a user of a blocked company can't sign in" do
    companies(:two).update!(acesso_bloqueado: true)
    post user_session_url, params: { user: { email: users(:one).email, password: "password" } }
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_match MENSAGEM, response.body
  end

  test "a signed-in user is signed out once the paid-through date has passed" do
    sign_in users(:one)
    get sorders_url
    assert_response :success

    companies(:two).update!(acesso_liberado_ate: Date.current - 1)
    get sorders_url
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_match MENSAGEM, response.body
  end

  test "access lasts through the paid-through day" do
    companies(:two).update!(acesso_liberado_ate: Date.current)
    sign_in users(:one)
    get sorders_url
    assert_response :success
  end

  test "users working in every company and admins are not affected" do
    companies(:two).update!(acesso_bloqueado: true)
    users(:two).update!(acesso_empresa: User::TODAS_EMPRESAS)
    sign_in users(:two)
    get sorders_url
    assert_response :success

    sign_out :user
    sign_in admins(:one)
    get sorders_url
    assert_response :success
  end
end
