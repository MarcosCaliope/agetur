require 'test_helper'

class PayablesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @conta = Payable.create!(tipo: "avulsa", descricao: "Aluguel", credor_nome: "Imobiliária", valor: 1000, vencimento: Date.new(2026, 10, 1))
  end

  test "lists open bills, flagging overdue ones" do
    get payables_url
    assert_response :success
    assert_select "tr.table-danger td", text: /Aluguel/
    get payables_url(situacao: "pagas")
    assert_select "td", text: /Aluguel/, count: 0
  end

  test "creates and edits a typed-in bill" do
    assert_difference("Payable.count") do
      post payables_url, params: { payable: { descricao: "Luz", credor_nome: "Enel", valor: "200", vencimento: "2026-10-20" } }
    end
    assert_equal "avulsa", Payable.last.tipo
    patch payable_url(@conta), params: { payable: { valor: "1100" } }
    assert_equal 1100, @conta.reload.valor
  end

  test "pays a bill through the cash book and reverses it" do
    get pagamento_payable_url(@conta)
    assert_response :success

    assert_difference("CashEntry.count") do
      patch pagar_payable_url(@conta), params: { pagamento: { data: "2026-10-09", forma_pagamento: "T", valor: "" } }
    end
    assert_redirected_to payables_url
    assert_equal [Date.new(2026, 10, 9), 1000, "T"], [@conta.reload.pago_em, @conta.valor_pago, @conta.cash_entry.forma_pagamento]

    get edit_payable_url(@conta)
    assert_redirected_to payables_url

    assert_difference("CashEntry.count", -1) { patch estornar_payable_url(@conta) }
    assert_not @conta.reload.pago?
  end

  test "payment needs a date" do
    patch pagar_payable_url(@conta), params: { pagamento: { data: "", forma_pagamento: "D" } }
    assert_response :unprocessable_entity
    assert_not @conta.reload.pago?
  end
end
