require 'test_helper'

class PickupTimesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @horario = PickupTime.create!(hotel: hotels(:one), destination: destinations(:one), hora: "07:40")
  end

  test "lists, creates, edits and deletes pickup times" do
    get pickup_times_url
    assert_select "td", text: "07:40"

    assert_difference("PickupTime.count") do
      post pickup_times_url, params: { pickup_time: { hotel_id: hotels(:two).id, destination_id: destinations(:one).id, hora: "08:15" } }
    end
    patch pickup_time_url(@horario), params: { pickup_time: { hora: "07:50" } }
    assert_equal "07:50", @horario.reload.hora
    assert_difference("PickupTime.count", -1) { delete pickup_time_url(@horario) }
  end

  test "shows validation errors" do
    post pickup_times_url, params: { pickup_time: { hotel_id: hotels(:one).id, destination_id: destinations(:one).id, hora: "25:00" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation li", text: /formato HH:MM/
  end
end
