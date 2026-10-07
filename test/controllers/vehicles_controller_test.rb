require 'test_helper'

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @vehicle = vehicles(:one)
  end

  test "should get index" do
    get vehicles_url
    assert_response :success
  end

  test "should get new" do
    get new_vehicle_url
    assert_response :success
  end

  test "should create vehicle" do
    assert_difference('Vehicle.count') do
      post vehicles_url, params: { vehicle: { brand: @vehicle.brand, city: @vehicle.city, color: @vehicle.color, comments: @vehicle.comments, license: @vehicle.license, smodel: @vehicle.smodel, state_id: @vehicle.state_id, year: @vehicle.year } }
    end

    assert_redirected_to vehicle_url(Vehicle.last)
  end

  test "should show vehicle" do
    get vehicle_url(@vehicle)
    assert_response :success
  end

  test "should get edit" do
    get edit_vehicle_url(@vehicle)
    assert_response :success
  end

  test "should update vehicle" do
    patch vehicle_url(@vehicle), params: { vehicle: { brand: @vehicle.brand, city: @vehicle.city, color: @vehicle.color, comments: @vehicle.comments, license: @vehicle.license, smodel: @vehicle.smodel, state_id: @vehicle.state_id, year: @vehicle.year } }
    assert_redirected_to vehicle_url(@vehicle)
  end

  test "should destroy vehicle" do
    assert_difference('Vehicle.count', -1) do
      delete vehicle_url(@vehicle)
    end

    assert_redirected_to vehicles_url
  end

  test "form has the SISTGER fields and saves them" do
    get new_vehicle_url
    (%w[license vehicle_type brand smodel manufacture_year year color capacity renavam chassis tank odometer licensing_year acquired_on insurance_kit city state_id comments]).each { |campo| assert_select "[name=?]", "vehicle[#{campo}]" }
    assert_select "label", text: "Ano de licenciamento"

    assert_difference("Vehicle.count") { post vehicles_url, params: { vehicle: { license: "ABC1234", vehicle_type: "VAN", capacity: "16", renavam: "123", licensing_year: 2024, acquired_on: "2014-05-02", insurance_kit: "S", state_id: states(:two).id } } }
    registro = Vehicle.order(:id).last
    assert_equal ["VAN", "16", "123", 2024, Date.new(2014, 5, 2), "S"], registro.values_at(*[:vehicle_type, :capacity, :renavam, :licensing_year, :acquired_on, :insurance_kit])
    get vehicle_url(registro)
    assert_response :success
  end
end
