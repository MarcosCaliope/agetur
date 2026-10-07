require 'test_helper'

class SorderItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sorder_item = sorder_items(:one)
  end

  test "should get index" do
    get sorder_items_url
    assert_response :success
  end

  test "should get commission report" do
    get showcomis_url
    assert_response :success
  end

  test "should filter commission report by vendor and inclusive date range" do
    sorder = sorders(:two)
    hoje = sorder.sorder_items.create!(vendor: vendors(:one), snomepax: "Hoje", amountcomission: 30, amountcomissionpay: 10)
    sorder.sorder_items.create!(vendor: vendors(:two), snomepax: "Outro Vendedor", amountcomission: 5)
    sorder.sorder_items.create!(vendor: vendors(:one), snomepax: "Mes Passado", created_at: 1.month.ago)

    dia = Date.current.iso8601
    get showcomis_url, params: { q: { vendor_id_eq: vendors(:one).id, created_at_gteq: dia, created_at_lteq: dia } }
    assert_response :success
    assert_select "td", text: hoje.snomepax
    assert_select "td", text: "20.0"
    assert_select "td", text: "Outro Vendedor", count: 0
    assert_select "td", text: "Mes Passado", count: 0
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
