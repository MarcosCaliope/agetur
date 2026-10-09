require 'test_helper'

class PickupTimeTest < ActiveSupport::TestCase
  test "one time per hotel and destination, as HH:MM" do
    PickupTime.create!(hotel: hotels(:one), destination: destinations(:one), hora: "07:40 ")
    repetido = PickupTime.new(hotel: hotels(:one), destination: destinations(:one), hora: "8:00")
    assert_not repetido.valid?
    assert_equal ["Hora deve estar no formato HH:MM", "Roteiro já tem horário neste hotel"], repetido.errors.full_messages
    assert_equal "07:40", PickupTime.hora_para(hotels(:one).id, destinations(:one).id)
    assert_nil PickupTime.hora_para(nil, destinations(:one).id)
  end

  test "an order passenger without a time takes the pickup time" do
    PickupTime.create!(hotel: hotels(:one), destination: sorders(:one).destination, hora: "06:30")
    item = sorders(:one).sorder_items.create!(snomepax: "Ana", hotel: hotels(:one))
    assert_equal "06:30", item.hour
  end
end
