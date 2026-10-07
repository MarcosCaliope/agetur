require 'test_helper'

class AdminsBackoffice::WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in admins(:one)
    get admins_backoffice_welcome_index_url
    assert_response :success
  end

end
