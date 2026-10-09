require 'test_helper'

class SorderItemPaymentTest < ActiveSupport::TestCase
  setup do
    @item = sorders(:one).sorder_items.create!(snomepax: "Ana", amount: 300, amountpay: 50, discount: 10)
  end

  test "a payment adds to the paid amount and posts an entry in the cash book" do
    pagamento = @item.pagamentos.create!(data: Date.new(2026, 10, 9), valor: 100, forma_pagamento: "O", descricao: "sinal", usuario: "a@b.c")

    assert_equal [150.0, 140.0], [@item.reload.amountpay, @item.total_passeio]
    entrada = pagamento.reload.cash_entry
    assert_equal ["E", "O", 100, "Recebimento de passeio", @item.sorder_id, @item.id, "a@b.c"],
                 [entrada.tipo, entrada.forma_pagamento, entrada.valor, entrada.categoria, entrada.sorder_id, entrada.sorder_item_id, entrada.usuario]
    assert_equal "Recebimento do passeio OS: #{@item.sorder_id} PAX: Ana - sinal", entrada.descricao
    assert entrada.automatico?

    assert_difference("CashEntry.count", -1) { pagamento.destroy! }
    assert_equal 50.0, @item.reload.amountpay
  end

  test "can skip the cash book" do
    assert_no_difference("CashEntry.count") do
      @item.pagamentos.create!(data: Date.current, valor: 10, lancar_no_caixa: false)
    end
  end

  test "can't take more than the balance or a payment on a closed order" do
    pagamento = @item.pagamentos.build(data: Date.current, valor: 240.01, forma_pagamento: "D")
    assert_not pagamento.valid?
    assert_match "maior que o saldo a receber (240,00)", pagamento.errors.full_messages.join

    @item.sorder.update!(encerrada: true)
    pagamento.valor = 10
    assert_not pagamento.valid?
    assert_includes pagamento.errors.full_messages, "A ordem de serviço está encerrada."
  end
end
