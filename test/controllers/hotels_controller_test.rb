require 'test_helper'

class HotelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @hotel = hotels(:one)
  end

  test "should get index" do
    get hotels_url
    assert_response :success
  end

  test "should search hotels by name" do
    @hotel.update!(sname: "Hotel Praia")
    hotels(:two).update!(sname: "Pousada Serra")
    get hotels_url, params: { busca: "praia" }
    assert_select "td", text: "Hotel Praia"
    assert_select "td", text: "Pousada Serra", count: 0
  end

  test "should get new" do
    get new_hotel_url
    assert_response :success
  end

  test "should create hotel" do
    assert_difference('Hotel.count') do
      post hotels_url, params: { hotel: { Valordiaria: @hotel.Valordiaria, address: @hotel.address, comments: @hotel.comments, email: @hotel.email, phone: @hotel.phone, sname: @hotel.sname } }
    end

    assert_redirected_to hotel_url(Hotel.last)
  end

  test "should show hotel" do
    get hotel_url(@hotel)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotel_url(@hotel)
    assert_response :success
  end

  test "should update hotel" do
    patch hotel_url(@hotel), params: { hotel: { Valordiaria: @hotel.Valordiaria, address: @hotel.address, comments: @hotel.comments, email: @hotel.email, phone: @hotel.phone, sname: @hotel.sname } }
    assert_redirected_to hotel_url(@hotel)
  end

  test "should destroy hotel" do
    assert_difference('Hotel.count', -1) do
      delete hotel_url(@hotel)
    end

    assert_redirected_to hotels_url
  end

  test "form has the SISTGER fields and saves them" do
    get new_hotel_url
    (%w[sname short_name document email address neighborhood city state_id zipcode phone phone2 fax contact comments] + %w[Valordiaria]).each { |campo| assert_select "[name=?]", "hotel[#{campo}]" }
    assert_select "label", text: "Nome reduzido"

    assert_difference("Hotel.count") { post hotels_url, params: { hotel: { sname: "HOTEL NOVO", short_name: "NOVO", neighborhood: "MEIRELES", city: "FORTALEZA", state_id: states(:two).id, zipcode: "60000", phone2: "8599", fax: "8533", contact: "Ana", document: "12.345", Valordiaria: 150.5 } } }
    registro = Hotel.order(:id).last
    assert_equal ["NOVO", "MEIRELES", "60000", "Ana", 150.5], registro.values_at(*[:short_name, :neighborhood, :zipcode, :contact, :Valordiaria])
    get hotel_url(registro)
    assert_response :success
  end
end
