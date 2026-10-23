require "test_helper"

class ConferenciaSinaisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    vendors(:one).update!(sname: "Gilda")
    booking = Booking.create!(data: Date.current, snome: "Ana", vendor: vendors(:one))
    @passeio = booking.items.create!(destination: destinations(:two), data_passeio: Date.current, valor: 200)
    PagamentoInformado.new(booking: booking, valor: 80, forma_pagamento: "O", usuario: "gilda@example.com",
                           comprovante: Rack::Test::UploadedFile.new(file_fixture("comprovante.pdf"), "application/pdf")).salvar
    @pagamento = @passeio.pagamentos.sole
  end

  test "lists the payments vendors reported, with their receipts" do
    get conferencia_sinais_url
    assert_response :success
    assert_select "table.sinais-a-conferir td", text: "Gilda"
    assert_select "table.sinais-a-conferir a", text: "Ver"
  end

  test "confirming posts it to the cash book" do
    assert_difference "CashEntry.count", 1 do
      patch confirmar_sinal_url(@pagamento)
    end
    assert_redirected_to conferencia_sinais_url
    assert_equal [true, "user_one@example.com"], [@pagamento.reload.confirmado?, @pagamento.conferido_por]
    assert_equal 80, @passeio.reload.pago
  end

  test "refusing keeps it marked with the reason" do
    assert_no_difference "CashEntry.count" do
      patch recusar_sinal_url(@pagamento), params: { motivo_recusa: "Não caiu" }
    end
    assert_equal ["recusado", "Não caiu"], @pagamento.reload.values_at(:situacao, :motivo_recusa)
    patch confirmar_sinal_url(@pagamento)
    assert_equal "Este recebimento não está a conferir.", flash[:alert]
  end

  test "the dashboard shows how many wait" do
    get root_url
    assert_select "#processos .dashboard-total", text: "1"
    assert_select "#processos a[href=?]", conferencia_sinais_path
  end

  test "a user without the route is sent home" do
    sign_out users(:one)
    sign_in users(:consulta)
    get conferencia_sinais_url
    assert_redirected_to root_url
  end
end
