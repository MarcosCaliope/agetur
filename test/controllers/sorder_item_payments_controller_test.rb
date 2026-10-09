require 'test_helper'

class SorderItemPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @item = sorders(:one).sorder_items.create!(snomepax: "Ana", amount: 300)
  end

  test "lists payments and adds one, posting it in the cash book" do
    get sorder_item_recebimentos_url(@item)
    assert_response :success
    assert_select "input[name='sorder_item_payment[valor]'][value='300.0']"

    assert_difference(["SorderItemPayment.count", "CashEntry.count"]) do
      post sorder_item_recebimentos_url(@item), params: { sorder_item_payment: { data: "2026-10-09", valor: "120", forma_pagamento: "O",
                                                                               lancar_no_caixa: "1" } }
    end
    assert_redirected_to sorder_item_recebimentos_url(@item)
    assert_equal [120.0, users(:one).email], [@item.reload.amountpay, @item.pagamentos.last.usuario]
  end

  test "refuses more than the balance" do
    post sorder_item_recebimentos_url(@item), params: { sorder_item_payment: { data: "2026-10-09", valor: "301", forma_pagamento: "D" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation", text: /maior que o saldo/
  end

  test "deletes a payment, but not on a closed order" do
    pagamento = @item.pagamentos.create!(data: Date.current, valor: 50, forma_pagamento: "D")
    sorders(:one).update!(encerrada: true)
    assert_no_difference("SorderItemPayment.count") { delete sorder_item_recebimento_url(@item, pagamento) }

    sorders(:one).update!(encerrada: false)
    assert_difference(["SorderItemPayment.count", "CashEntry.count"], -1) { delete sorder_item_recebimento_url(@item, pagamento) }
  end
end
