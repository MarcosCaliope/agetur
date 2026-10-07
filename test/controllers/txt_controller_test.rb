require 'test_helper'

class TxtControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should import customers from txt" do
    assert_difference('Customer.count', 1) do
      post '/txt/importar', params: { txt: fixture_file_upload('customers.txt', 'text/plain') }
    end
    assert_redirected_to '/txt'
    assert_equal "Imported with successful", flash[:success]
  end

  test "should redirect with an error when no file is sent" do
    assert_no_difference('Customer.count') do
      post '/txt/importar'
    end
    assert_redirected_to '/txt'
    assert_equal "Selecione um arquivo para importar.", flash[:error]
  end
end
