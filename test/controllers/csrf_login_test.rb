require 'test_helper'

# Sign in with CSRF protection on, as in development and production (the
# test environment turns it off). Looking up the signed-in account before the
# token is checked made Devise reset it, so every login failed.
class CsrfLoginTest < ActionDispatch::IntegrationTest
  setup do
    @protecao = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @protecao
  end

  test "a user signs in" do
    get new_user_session_url
    post user_session_url, params: { authenticity_token: token, user: { email: users(:one).email, password: "password" } }
    assert_redirected_to root_url
    follow_redirect!
    assert_select ".empresa-atual", text: "Empresa: #{companies(:two).name}"
  end

  test "an admin signs in" do
    get new_admin_session_url
    post admin_session_url, params: { authenticity_token: token, admin: { email: admins(:one).email, password: "password" } }
    assert_redirected_to root_url
  end

  test "a form posted without the token is still refused" do
    sign_in users(:one)
    get hotels_url
    assert_no_difference("Hotel.unscoped.count") do
      post hotels_url, params: { hotel: { sname: "SEM TOKEN" } }
    end
    assert_response :unprocessable_entity
  end

  private

  def token
    css_select("input[name=authenticity_token]").first["value"]
  end
end
