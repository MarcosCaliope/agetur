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
      post sorders_url, params: { sorder: { data: @sorder.data, sobservacoes: @sorder.sobservacoes,
        destination_id: @sorder.destination_id, tourguide_id: @sorder.tourguide_id,
        driver_id: @sorder.driver_id, vehicle_id: @sorder.vehicle_id, company_id: @sorder.company_id } }
    end

    assert_redirected_to sorder_url(Sorder.last)
  end

  test "should show sorder" do
    get sorder_url(@sorder)
    assert_response :success
  end

  test "should filter sorders by destination" do
    get sorders_url, params: { q: { destination_id_eq: destinations(:one).id } }
    assert_response :success
    assert_select "tbody tr", count: 0
    get sorders_url, params: { q: { destination_id_eq: destinations(:two).id, data_gteq: "2021-07-01", data_lteq: "2021-07-03" } }
    assert_select "tbody tr", count: Sorder.count
  end

  test "should create sorder with commission fields on passengers" do
    assert_difference('SorderItem.count') do
      post sorders_url, params: { sorder: { data: @sorder.data, destination_id: @sorder.destination_id, tourguide_id: @sorder.tourguide_id,
        driver_id: @sorder.driver_id, vehicle_id: @sorder.vehicle_id, company_id: @sorder.company_id,
        sorder_items_attributes: { "0" => { snomepax: "Maria", qtdepax: 2, amount: 100, amountpay: 40, vendor_id: vendors(:one).id,
          amountcomission: 30, amountcomissionpay: 10, amountcomissionrep: 5, amountcomissionreppay: 2, scancelado: "N" } } } }
    end
    item = Sorder.last.sorder_items.first
    assert_equal ["Maria", 10.0, 5.0, 2.0, "N"], [item.snomepax, item.amountcomissionpay, item.amountcomissionrep, item.amountcomissionreppay, item.scancelado]
  end

  test "should hide cancelled passengers and show totals" do
    @sorder.sorder_items.create!(snomepax: "Ativo", qtdepax: 2, scancelado: "N")
    @sorder.sorder_items.create!(snomepax: "Desistiu", qtdepax: 3, scancelado: "S")
    get sorder_url(@sorder)
    assert_select "td", text: "Ativo"
    assert_select "td", text: "Desistiu", count: 0
    assert_match "Total de PAX:</strong> 2", response.body
  end

  test "should show sorder when its company has no logo" do
    @sorder.company.update!(logoform: nil)
    get sorder_url(@sorder)
    assert_response :success
  end

  test "should export sorder as pdf" do
    get export_sorder_url(sorders(:two))
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
  end

  test "should get edit" do
    get edit_sorder_url(@sorder)
    assert_response :success
    assert_select "a[href=?]", export_sorder_path(@sorder), text: "Exportar PDF"
  end

  test "should not link to export on new" do
    get new_sorder_url
    assert_select "a", text: "Exportar PDF", count: 0
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
