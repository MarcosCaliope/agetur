require 'test_helper'

class DestinationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @destination = destinations(:one)
  end

  test "should get index" do
    get destinations_url
    assert_response :success
  end

  test "should get new" do
    get new_destination_url
    assert_response :success
  end

  test "should create destination" do
    assert_difference('Destination.count') do
      post destinations_url, params: { destination: { description: @destination.description, distance: @destination.distance, state_id: @destination.state_id, valuecard: @destination.valuecard, valuecardchd: @destination.valuecardchd, valuenet: @destination.valuenet, valuenetchd: @destination.valuenetchd, valuenormal: @destination.valuenormal, valuenormalchd: @destination.valuenormalchd } }
    end

    assert_redirected_to destination_url(Destination.last)
  end

  test "should show destination" do
    get destination_url(@destination)
    assert_response :success
  end

  test "should get edit" do
    get edit_destination_url(@destination)
    assert_response :success
  end

  test "should update destination" do
    patch destination_url(@destination), params: { destination: { description: @destination.description, distance: @destination.distance, state_id: @destination.state_id, valuecard: @destination.valuecard, valuecardchd: @destination.valuecardchd, valuenet: @destination.valuenet, valuenetchd: @destination.valuenetchd, valuenormal: @destination.valuenormal, valuenormalchd: @destination.valuenormalchd } }
    assert_redirected_to destination_url(@destination)
  end

  test "should destroy destination" do
    assert_difference('Destination.count', -1) do
      delete destination_url(@destination)
    end

    assert_redirected_to destinations_url
  end

  test "form has the combo values and saves them" do
    get new_destination_url
    %w[value_combo value_combo_chd value_net_combo value_net_combo_chd].each { |campo| assert_select "[name=?]", "destination[#{campo}]" }
    patch destination_url(@destination), params: { destination: { value_combo: 150, value_net_combo: 120 } }
    assert_equal [150.0, 120.0], @destination.reload.values_at(:value_combo, :value_net_combo)
    get destination_url(@destination)
    assert_select "strong", text: "Net combo:"
  end
end
