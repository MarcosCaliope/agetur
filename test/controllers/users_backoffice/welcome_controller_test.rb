require 'test_helper'

class UsersBackoffice::WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in users(:one)
    get users_backoffice_welcome_index_url
    assert_response :success
  end

end
