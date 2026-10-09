require 'test_helper'

class BookingItemTest < ActiveSupport::TestCase
  setup do
    @destino = destinations(:two)
    @destino.update!(valuenormal: 100, valuenormalchd: 60)
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 11, 5, 8))
    vendors(:one).update!(commission: 10)
    @booking = Booking.create!(data: Date.new(2026, 10, 9), snome: "Ana", vendor: vendors(:one), hotel: hotels(:one), apto: "12",
                               telefone: "85 9999", documenttype: "RG", document: "123")
    @booking.companions.create!(snome: "Bia", chd: true)
    @passeio = @booking.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 5), qtdepax: 2, qtdechd: 1)
  end

  test "suggests the price and the pickup time at the hotel" do
    assert_equal 260, @passeio.valor
    PickupTime.create!(hotel: hotels(:one), destination: @destino, hora: "07:40")
    outro = @booking.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 6), valor: 90)
    assert_equal ["07:40", 90], [outro.hora, outro.valor]
  end

  test "child price is half the adult one when the destination has none" do
    @destino.update!(valuenormalchd: nil)
    assert_equal 250, @booking.items.create!(destination: @destino, data_passeio: Date.current, qtdepax: 2, qtdechd: 1).valor
  end

  test "placing it in an order creates the passenger with pax list, commission and down payments" do
    sinal = @passeio.pagamentos.create!(data: Date.new(2026, 10, 9), valor: 60, forma_pagamento: "O")
    assert_equal "Sinal do agendamento nº #{@booking.id} (#{@destino.description}) PAX: Ana", sinal.cash_entry.descricao
    assert_nil sinal.cash_entry.sorder_id

    assert_equal [@ordem], @passeio.ordens_candidatas.to_a
    item = @passeio.lancar_na_os!(@ordem)

    assert_equal ["Ana", hotels(:one), "12", "85 9999", "RG", "123", 2, 1, 260.0, 26.0, 60.0, vendors(:one), "N"],
                 [item.snomepax, item.hotel, item.apto, item.phone, item.documenttype, item.document, item.qtdepax, item.qtdechd,
                  item.amount, item.amountcomission, item.amountpay, item.vendor, item.scancelado]
    assert_equal ["Bia (CHD)"], item.companions.map(&:descricao)
    assert_equal item, @passeio.reload.sorder_item
    assert_equal [item.id, @ordem.id, item.id], [sinal.reload.sorder_item_id, sinal.cash_entry.sorder_id, sinal.cash_entry.sorder_item_id]
    assert_empty @passeio.ordens_candidatas.where.not(id: @ordem.id)

    erro = assert_raises(BookingItem::NaoLancado) { @passeio.lancar_na_os!(@ordem) }
    assert_match "já lançado na OS nº #{@ordem.id}", erro.message
  end

  test "commission comes from the vendor's % for the destination, and none for vendors not paid commission" do
    VendorDestination.create!(vendor: vendors(:one), destination: @destino, commission: 15)
    assert_equal 39.0, @passeio.comissao_prevista
    vendors(:one).update!(no_commission: true)
    assert_equal 0, @passeio.reload.comissao_prevista
  end

  test "refuses closed orders, other destinations and cancelled tours" do
    @ordem.update!(encerrada: true)
    assert_raises(BookingItem::NaoLancado, match: /encerrada/) { @passeio.lancar_na_os!(@ordem) }
    @ordem.update!(encerrada: false, destination: destinations(:one))
    assert_raises(BookingItem::NaoLancado, match: /outro roteiro/) { @passeio.lancar_na_os!(@ordem) }
    @ordem.update!(destination: @destino)
    @passeio.update!(cancelado: true)
    assert_raises(BookingItem::NaoLancado, match: /cancelado/) { @passeio.lancar_na_os!(@ordem) }
  end

  test "taking it out of the order, or deleting the passenger there, hands the down payments back" do
    sinal = @passeio.pagamentos.create!(data: Date.current, valor: 60, forma_pagamento: "D")
    @passeio.lancar_na_os!(@ordem)

    assert_difference("SorderItem.count", -1) { @passeio.retirar_da_os! }
    assert_not @passeio.reload.lancado?
    assert_equal [nil, @passeio.id, nil], [sinal.reload.sorder_item_id, sinal.booking_item_id, sinal.cash_entry.sorder_id]

    item = @passeio.lancar_na_os!(@ordem)
    assert_no_difference(["SorderItemPayment.count", "CashEntry.count"]) { item.destroy! }
    assert_not @passeio.reload.lancado?
    assert_nil sinal.reload.sorder_item_id
  end

  test "saving an order pulls in its booked tours, tying a passenger typed with the same name" do
    jose = Booking.create!(data: Date.current, snome: "José Lima", vendor: vendors(:one), telefone: "85 2")
    passeio_jose = jose.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 5), valor: 80)
    jose.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 5), valor: 80, cancelado: true)
    jose.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 6), valor: 80)
    sinal = @passeio.pagamentos.create!(data: Date.current, valor: 60, forma_pagamento: "D")
    digitado = @ordem.sorder_items.create!(snomepax: "jose  LIMA", amount: 90)

    resultado = @ordem.incluir_agendamentos!

    assert_equal [[:incluido, @passeio], [:vinculado, passeio_jose]], resultado.sort_by { |r| r.first.to_s }
    assert_equal "Ana", @passeio.reload.sorder_item.snomepax
    assert_equal 60.0, @passeio.sorder_item.amountpay
    assert_equal sinal.reload.sorder_item, @passeio.sorder_item
    assert_equal digitado, passeio_jose.reload.sorder_item
    assert_equal ["jose  LIMA", 90.0, "85 2", vendors(:one).id], [digitado.reload.snomepax, digitado.amount, digitado.phone, digitado.vendor_id],
                 "typed values stay; blanks come from the booking"
    assert_equal 2, @ordem.sorder_items.count
    assert_empty @ordem.incluir_agendamentos!, "nothing left to pull in"
  end

  test "a tour taken out of an order isn't pulled back in by itself, nor into closed orders" do
    @passeio.lancar_na_os!(@ordem)
    @passeio.sorder_item.destroy!
    assert_not @passeio.reload.inclusao_automatica
    assert_empty @ordem.incluir_agendamentos!
    @passeio.lancar_na_os!(@ordem) # by hand it still goes

    outro = @booking.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 5))
    @ordem.update!(encerrada: true)
    assert_empty @ordem.incluir_agendamentos!
    assert_not outro.reload.lancado?
  end

  test "reports a tour that can't be placed" do
    vendors(:one).update_columns(active: false)
    assert_equal [[:erro, @passeio, "Vendedor está inativo"]], @ordem.incluir_agendamentos!
  end

  test "a placed tour or booking can't be deleted" do
    @passeio.lancar_na_os!(@ordem)
    assert_not @passeio.destroy
    assert_not @booking.reload.destroy
    assert_match "retire-os da OS", @booking.errors.full_messages.join
  end

  test "down payment can't exceed the tour price" do
    sinal = @passeio.pagamentos.build(data: Date.current, valor: 261, forma_pagamento: "D")
    assert_not sinal.valid?
    assert_match "maior que o saldo a receber (260,00)", sinal.errors.full_messages.join
  end

  test "booking totals and suggested pax" do
    @passeio.pagamentos.create!(data: Date.current, valor: 60, forma_pagamento: "D")
    @booking.items.create!(destination: @destino, data_passeio: Date.current, valor: 50, cancelado: true)
    assert_equal [260, 60, 1, 1], [@booking.total, @booking.pago, @booking.pax_sugerido, @booking.chd_sugerido]
  end

  test "can add the passenger to the customer register" do
    booking = Booking.create!(data: Date.current, snome: "Novo Cliente", vendor: vendors(:one), documenttype: "CPF", document: "111",
                              telefone: "85 1", cadastrar_cliente: true)
    assert_equal ["Novo Cliente", "111", "85 1"], [booking.customer.nome, booking.customer.document, booking.customer.phone]
  end
end
