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
