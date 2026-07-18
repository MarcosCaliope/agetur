require 'test_helper'

class SordersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sorder = sorders(:one)
  end

  test "should get index" do
    get sorders_url
    assert_response :success
  end

  test "should get new" do
    get new_sorder_url
    assert_response :success
  end

  test "should create sorder" do
    assert_difference('Sorder.count') do
      post sorders_url, params: { sorder: { data: @sorder.data, sobservacoes: @sorder.sobservacoes } }
    end

    assert_redirected_to sorder_url(Sorder.last)
  end

  test "should show sorder" do
    get sorder_url(@sorder)
    assert_response :success
  end

  test "should get edit" do
    get edit_sorder_url(@sorder)
    assert_response :success
  end

  test "should update sorder" do
    patch sorder_url(@sorder), params: { sorder: { data: @sorder.data, sobservacoes: @sorder.sobservacoes } }
    assert_redirected_to sorder_url(@sorder)
  end

  test "should destroy sorder" do
    assert_difference('Sorder.count', -1) do
      delete sorder_url(@sorder)
    end

    assert_redirected_to sorders_url
  end
end
