require 'test_helper'

class TourguidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tourguide = tourguides(:one)
  end

  test "should get index" do
    get tourguides_url
    assert_response :success
  end

  test "should get new" do
    get new_tourguide_url
    assert_response :success
  end

  test "should create tourguide" do
    assert_difference('Tourguide.count') do
      post tourguides_url, params: { tourguide: { address: @tourguide.address, comments: @tourguide.comments, email: @tourguide.email, phone: @tourguide.phone, sname: @tourguide.sname } }
    end

    assert_redirected_to tourguide_url(Tourguide.last)
  end

  test "should show tourguide" do
    get tourguide_url(@tourguide)
    assert_response :success
  end

  test "should get edit" do
    get edit_tourguide_url(@tourguide)
    assert_response :success
  end

  test "should update tourguide" do
    patch tourguide_url(@tourguide), params: { tourguide: { address: @tourguide.address, comments: @tourguide.comments, email: @tourguide.email, phone: @tourguide.phone, sname: @tourguide.sname } }
    assert_redirected_to tourguide_url(@tourguide)
  end

  test "should destroy tourguide" do
    assert_difference('Tourguide.count', -1) do
      delete tourguide_url(@tourguide)
    end

    assert_redirected_to tourguides_url
  end
end
