require "test_helper"

class PagamentoInformadoTest < ActiveSupport::TestCase
  setup do
    @destino = destinations(:two)
    @destino.update!(valuenormal: 100, valuenormalchd: 50)
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 11, 5, 8), destination: @destino, encerrada: false)
    @booking = Booking.create!(data: Date.new(2026, 10, 9), snome: "Ana", vendor: vendors(:one))
    @primeiro = @booking.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 5)) # 100
    @segundo = @booking.items.create!(destination: @destino, data_passeio: Date.new(2026, 11, 6), qtdepax: 1, qtdechd: 1) # 150
  end

  def informar(valor, **outros)
    PagamentoInformado.new(booking: @booking, valor: valor, forma_pagamento: "O", usuario: "vendedor@example.com", **outros)
  end

  test "splits the payment over the tours by date, waiting for the office" do
    assert_no_difference "CashEntry.count" do
      assert informar(130).salvar
    end
    assert_equal [[100, "conferir"], [30, "conferir"]],
                 [@primeiro, @segundo].map { |passeio| passeio.pagamentos.reload.map { |p| [p.valor.to_i, p.situacao] }.first }
    assert_equal 0, @booking.pago
    assert_equal 0, @primeiro.reload.pago
    assert_equal 100, @primeiro.a_conferir
  end

  test "refuses more than what's left, counting what still waits to be checked" do
    informar(200).salvar
    pagamento = informar(60)
    assert_not pagamento.salvar
    assert_match(/maior que o saldo a receber \(50,00\)/, pagamento.errors.full_messages.to_sentence)
  end

  test "attaches the receipt to each part" do
    arquivo = Rack::Test::UploadedFile.new(file_fixture("comprovante.pdf"), "application/pdf")
    assert informar(130, comprovante: arquivo).salvar
    pagamentos = SorderItemPayment.where(booking_item_id: [@primeiro.id, @segundo.id])
    assert pagamentos.all? { |p| p.comprovante.attached? }
    assert_equal 1, pagamentos.map { |p| p.comprovante.blob.id }.uniq.size
  end

  test "refuses a receipt that isn't an image or PDF" do
    arquivo = Rack::Test::UploadedFile.new(file_fixture("customers.txt"), "text/plain")
    pagamento = informar(10, comprovante: arquivo)
    assert_not pagamento.salvar
    assert_includes pagamento.errors[:comprovante], "deve ser uma imagem (PNG, JPG, GIF, WebP) ou PDF"
  end

  test "confirming makes it paid and posts it to the cash book; refusing moves nothing" do
    informar(130).salvar
    primeiro, segundo = SorderItemPayment.a_conferir.order(:id).to_a
    assert_difference "CashEntry.count", 1 do
      primeiro.confirmar!("caixa@example.com")
    end
    assert_equal ["caixa@example.com", 100], [primeiro.conferido_por, primeiro.cash_entry.valor.to_i]
    segundo.recusar!("caixa@example.com", "PIX não caiu")
    assert_equal [100, 0], [@primeiro.reload.pago, @segundo.reload.pago]
    assert_equal ["recusado", "PIX não caiu"], [segundo.situacao, segundo.motivo_recusa]
    assert_raises(ActiveRecord::RecordInvalid) { segundo.confirmar!("caixa@example.com") }
  end

  test "a payment waiting when the tour goes into an order moves the passenger's paid amount once confirmed" do
    informar(100).salvar
    item = @primeiro.lancar_na_os!(@ordem)
    assert_equal 0, item.reload.amountpay.to_f
    pagamento = item.pagamentos.sole
    assert pagamento.a_conferir?

    pagamento.confirmar!("caixa@example.com")
    assert_equal 100, item.reload.amountpay
    assert_equal item, pagamento.cash_entry.sorder_item
  end

  test "a tour already in an order takes the payment on its passenger" do
    item = @segundo.lancar_na_os!(@ordem)
    assert informar(250).salvar
    assert_equal 150, item.pagamentos.a_conferir.sum(:valor)
    assert_equal 0, item.reload.amountpay.to_f
  end
end
