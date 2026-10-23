require "test_helper"

class VendasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vendedor = vendors(:one)
    @vendedor.update!(sname: "Gilda")
    @login = User.create!(email: "gilda@example.com", password: "password", vendor: @vendedor, acesso_total: true,
                          permissoes: ["sorders#index"])
    destinations(:two).update!(description: "Jericoacoara", valuenormal: 100, valuenormalchd: 50)
    sign_in @login
  end

  def venda_params(pagamento = {})
    { booking: { snome: "Ana Lima", telefone: "85 9999", hotel_id: hotels(:one).id, apto: "12",
                 companions_attributes: { "0" => { snome: "Bia", chd: "1" } },
                 items_attributes: { "0" => { destination_id: destinations(:two).id, data_passeio: "2026-11-05", qtdepax: "1", qtdechd: "1", valor: "" } } },
      pagamento_informado: pagamento }
  end

  test "a vendor login works only in its vendor's company and opens nothing else" do
    assert_equal [@vendedor.company_id, false, []], [@login.company_id, @login.acesso_total, @login.permissoes]
    get sorders_url
    assert_redirected_to root_url
    get root_url
    assert_redirected_to vendas_url
  end

  test "sells tours as a booking of their own, with a payment and receipt waiting for the office" do
    comprovante = fixture_file_upload("comprovante.pdf", "application/pdf")
    assert_difference -> { Booking.count } => 1, -> { BookingItem.count } => 1, -> { SorderItemPayment.a_conferir.count } => 1,
                      -> { CashEntry.count } => 0 do
      post vendas_url, params: venda_params(valor: "60", forma_pagamento: "O", comprovante: comprovante)
    end
    booking = Booking.order(:id).last
    assert_redirected_to venda_url(booking)
    assert_equal [@vendedor, Date.current, "gilda@example.com", ["Bia"]], [booking.vendor, booking.data, booking.usuario, booking.companions.map(&:snome)]
    passeio = booking.items.sole
    assert_equal 150, passeio.valor # table price: adult + child
    assert passeio.pagamentos.sole.comprovante.attached?

    follow_redirect!
    assert_select "td", text: "Jericoacoara"
    assert_select ".badge", text: "a conferir"
    assert_select ".badge", text: "aguardando OS"
  end

  test "the sales form has the customer, pax list, tours with the table price, and the payment" do
    get new_venda_url
    assert_response :success
    assert_select "input[name='booking[snome]']"
    assert_select "select[name='booking[items_attributes][0][destination_id]'] option", text: "Jericoacoara (R$ 100,00 adulto)"
    assert_select "a.add_fields", text: "[Adicionar passeio]"
    assert_select "input[type=file][name='pagamento_informado[comprovante]']"
    assert_select "select[name='booking[vendor_id]']", count: 0
  end

  test "a sale without payment is fine, but an invalid payment saves nothing" do
    assert_difference "Booking.count", 1 do
      post vendas_url, params: venda_params
    end
    assert_no_difference ["Booking.count", "BookingItem.count", "SorderItemPayment.count"] do
      post vendas_url, params: venda_params(valor: "999", forma_pagamento: "O")
    end
    assert_response :unprocessable_entity
    assert_select "#error_explanation", text: /maior que o saldo a receber/
  end

  test "reports another payment, and sees only its own sales" do
    post vendas_url, params: venda_params
    booking = Booking.order(:id).last
    post pagamento_venda_url(booking), params: { pagamento_informado: { valor: "150", forma_pagamento: "R" } }
    assert_redirected_to venda_url(booking)
    assert_equal 150, booking.items.sole.a_conferir

    alheio = Booking.create!(data: Date.current, snome: "Outro", vendor: vendors(:two), company: companies(:two))
    get venda_url(alheio)
    assert_response :not_found
    get vendas_url
    assert_select "td a", text: "Ana Lima"
    assert_select "td", text: "Outro", count: 0
  end

  test "an inactive vendor can't sell" do
    @vendedor.update!(active: false)
    get new_venda_url
    assert_redirected_to root_url
  end

  test "office users don't open the sales screen" do
    sign_out @login
    sign_in users(:one)
    get vendas_url
    assert_redirected_to root_url
  end
end
