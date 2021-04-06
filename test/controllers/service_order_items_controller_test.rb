require 'test_helper'

class ServiceOrderItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @service_order_item = service_order_items(:one)
  end

  test "should get index" do
    get service_order_items_url
    assert_response :success
  end

  test "should get new" do
    get new_service_order_item_url
    assert_response :success
  end

  test "should create service_order_item" do
    assert_difference('ServiceOrderItem.count') do
      post service_order_items_url, params: { service_order_item: { agency_id: @service_order_item.agency_id, amount: @service_order_item.amount, amountcomission: @service_order_item.amountcomission, amountpay: @service_order_item.amountpay, apto: @service_order_item.apto, comments: @service_order_item.comments, document: @service_order_item.document, documenttype: @service_order_item.documenttype, hotel_id: @service_order_item.hotel_id, hour: @service_order_item.hour, nomepax: @service_order_item.nomepax, phone: @service_order_item.phone, qtdepax: @service_order_item.qtdepax, service_order_id: @service_order_item.service_order_id, vendor_id: @service_order_item.vendor_id } }
    end

    assert_redirected_to service_order_item_url(ServiceOrderItem.last)
  end

  test "should show service_order_item" do
    get service_order_item_url(@service_order_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_service_order_item_url(@service_order_item)
    assert_response :success
  end

  test "should update service_order_item" do
    patch service_order_item_url(@service_order_item), params: { service_order_item: { agency_id: @service_order_item.agency_id, amount: @service_order_item.amount, amountcomission: @service_order_item.amountcomission, amountpay: @service_order_item.amountpay, apto: @service_order_item.apto, comments: @service_order_item.comments, document: @service_order_item.document, documenttype: @service_order_item.documenttype, hotel_id: @service_order_item.hotel_id, hour: @service_order_item.hour, nomepax: @service_order_item.nomepax, phone: @service_order_item.phone, qtdepax: @service_order_item.qtdepax, service_order_id: @service_order_item.service_order_id, vendor_id: @service_order_item.vendor_id } }
    assert_redirected_to service_order_item_url(@service_order_item)
  end

  test "should destroy service_order_item" do
    assert_difference('ServiceOrderItem.count', -1) do
      delete service_order_item_url(@service_order_item)
    end

    assert_redirected_to service_order_items_url
  end
end
