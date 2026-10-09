require 'test_helper'

class BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @destino = destinations(:two)
    @destino.update!(valuenormal: 100, valuenormalchd: 50)
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 11, 5, 8))
    @booking = Booking.create!(data: Date.new(2026, 10, 9), snome: "Ana", vendor: vendors(:one), hotel: hotels(:one))
    @passeio = @booking.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 5))
  end

  test "creates a booking with its pax list, then adds a tour" do
    assert_difference(["Booking.count", "BookingCompanion.count"]) do
      post bookings_url, params: { booking: { data: "2026-10-09", snome: "Carlos", vendor_id: vendors(:one).id, hotel_id: hotels(:one).id,
                                              companions_attributes: { "0" => { snome: "Dora", chd: "1" }, "1" => { snome: "" } } } }
    end
    booking = Booking.last
    assert_redirected_to booking_url(booking)
    assert_equal users(:one).email, booking.usuario

    get booking_url(booking)
    assert_select "input[name='booking_item[qtdechd]'][value='1']"

    post booking_items_url(booking), params: { booking_item: { destination_id: @destino.id, data_passeio: "2026-11-05", qtdepax: "1", qtdechd: "1" } }
    follow_redirect!
    assert_select ".alert-success", text: /Já existe OS do roteiro nesta data \(nº #{@ordem.id}\)/
    assert_equal 150, booking.items.last.valor
  end

  test "shows the booking with a button to place the tour in the order" do
    get booking_url(@booking)
    assert_response :success
    assert_select "a[href='#{lancar_booking_item_path(@booking, @passeio, sorder_id: @ordem.id)}']"
  end

  test "places a tour in the order and takes it back out" do
    assert_difference("SorderItem.count") do
      patch lancar_booking_item_url(@booking, @passeio, sorder_id: @ordem.id), headers: { "HTTP_REFERER" => booking_url(@booking) }
    end
    assert_redirected_to booking_url(@booking)
    assert @passeio.reload.lancado?

    get edit_booking_item_url(@booking, @passeio)
    assert_select ".alert-info", text: /lançado na OS nº #{@ordem.id}/
    assert_difference("SorderItem.count", -1) { patch retirar_booking_item_url(@booking, @passeio) }
  end

  test "won't place a tour in a closed order" do
    @ordem.update!(encerrada: true)
    patch lancar_booking_item_url(@booking, @passeio, sorder_id: @ordem.id)
    follow_redirect!
    assert_select ".alert-danger", text: /está encerrada/
  end

  test "lists tours by period and status, and the pending ones by date and destination" do
    get bookings_url(inicio: "2026-11-01", fim: "2026-11-30", situacao: "pendentes")
    assert_select "td", text: "Ana"
    get bookings_url(inicio: "2026-11-01", fim: "2026-11-30", situacao: "lancados")
    assert_select "td", text: "Ana", count: 0

    get pendentes_bookings_url(inicio: "2026-11-01")
    assert_response :success
    assert_select ".card-header", text: /05\/11\/2026 · #{@destino.description}/
    assert_select "a", text: "Lançar na OS nº #{@ordem.id}"
  end

  test "lists bookings that have no tour yet" do
    vazio = Booking.create!(data: Date.new(2026, 10, 9), snome: "Sem Passeio", vendor: vendors(:one))
    get bookings_url
    assert_select ".alert-warning a[href='#{booking_path(vazio)}']", text: "nº #{vazio.id} – Sem Passeio"
    assert_select ".alert-warning a", text: /Ana/, count: 0

    get bookings_url(busca: "outro nome")
    assert_select ".alert-warning", count: 0
  end

  test "takes a down payment on a tour" do
    get booking_item_recebimentos_url(@booking, @passeio)
    assert_select "input[name='sorder_item_payment[valor]'][value='100.0']"
    assert_difference(["SorderItemPayment.count", "CashEntry.count"]) do
      post booking_item_recebimentos_url(@booking, @passeio), params: { sorder_item_payment: { data: "2026-10-09", valor: "40",
                                                                                               forma_pagamento: "D", lancar_no_caixa: "1" } }
    end
    get booking_url(@booking)
    assert_select "td.text-right", text: "R$ 40,00"
  end

  test "deletes a booking unless a tour is in an order" do
    @passeio.lancar_na_os!(@ordem)
    assert_no_difference("Booking.count") { delete booking_url(@booking) }
    @passeio.retirar_da_os!
    assert_difference("Booking.count", -1) { delete booking_url(@booking) }
  end
end
