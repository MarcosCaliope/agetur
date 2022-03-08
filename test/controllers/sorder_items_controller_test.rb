require 'test_helper'

class SorderItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sorder_item = sorder_items(:one)
  end

  test "should get index" do
    get sorder_items_url
    assert_response :success
  end

  test "should get new" do
    get new_sorder_item_url
    assert_response :success
  end

  test "should create sorder_item" do
    assert_difference('SorderItem.count') do
      post sorder_items_url, params: { sorder_item: { comments: @sorder_item.comments, sorder_id: @sorder_item.sorder_id } }
    end

    assert_redirected_to sorder_item_url(SorderItem.last)
  end

  test "should show sorder_item" do
    get sorder_item_url(@sorder_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_sorder_item_url(@sorder_item)
    assert_response :success
  end

  test "should update sorder_item" do
    patch sorder_item_url(@sorder_item), params: { sorder_item: { comments: @sorder_item.comments, sorder_id: @sorder_item.sorder_id } }
    assert_redirected_to sorder_item_url(@sorder_item)
  end

  test "should destroy sorder_item" do
    assert_difference('SorderItem.count', -1) do
      delete sorder_item_url(@sorder_item)
    end

    assert_redirected_to sorder_items_url
  end
end
