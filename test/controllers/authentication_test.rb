require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  CADASTROS = %w[/agencies /companies /customers /destinations /drivers /hotels /sorder_items
                 /sorders /states /tourguides /vehicles /vendors /showcomis /txt]

  test "cadastros redirect to sign in when logged out" do
    CADASTROS.each do |path|
      get path
      assert_redirected_to new_user_session_path, "#{path} should require login"
    end
  end

  test "writes are blocked when logged out" do
    assert_no_difference('State.count') do
      post states_url, params: { state: { uf: "SC", name: "Santa Catarina" } }
    end
    assert_redirected_to new_user_session_path

    assert_no_difference('Customer.count') do
      post '/txt/importar', params: { txt: fixture_file_upload('customers.txt', 'text/plain') }
    end
    assert_redirected_to new_user_session_path
  end

  test "pdf and json formats also require login" do
    get hotels_url(format: :pdf)
    assert_response :unauthorized
    get sorders_url(format: :json)
    assert_response :unauthorized
  end

  test "a signed in user can access cadastros" do
    sign_in users(:one)
    CADASTROS.each do |path|
      get path
      assert_response :success, "#{path} should be accessible to a user"
    end
  end

  test "a signed in admin can access cadastros" do
    sign_in admins(:one)
    get sorders_url
    assert_response :success
  end

  test "home page and sign in pages stay public" do
    get root_url
    assert_response :success
    get new_user_session_url
    assert_response :success
    get new_admin_session_url
    assert_response :success
  end

  test "user self sign-up is closed" do
    get "/users/sign_up"
    assert_response :not_found
    assert_no_difference('User.count') do
      post "/users", params: { user: { email: "intruso@example.com", password: "senha123", password_confirmation: "senha123" } }
    end
    assert_response :not_found
  end

  test "admin self sign-up is closed" do
    get "/admins/sign_up"
    assert_response :not_found
    assert_no_difference('Admin.count') do
      post "/admins", params: { admin: { email: "intruso@example.com", password: "senha123", password_confirmation: "senha123" } }
    end
    assert_response :not_found
  end

  test "an existing admin can still sign in" do
    post admin_session_url, params: { admin: { email: admins(:one).email, password: "password" } }
    assert_redirected_to root_url
    get sorders_url
    assert_response :success
  end

  test "after signing in the user returns to the page they asked for" do
    get hotels_url
    post user_session_url, params: { user: { email: users(:one).email, password: "password" } }
    assert_redirected_to hotels_url
  end
end
