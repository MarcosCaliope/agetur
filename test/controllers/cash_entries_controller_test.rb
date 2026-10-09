require 'test_helper'

class CashEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ontem = CashEntry.create!(data: Date.new(2026, 10, 8), tipo: "E", categoria: "Suprimento", forma_pagamento: "D", valor: 100, descricao: "Troco")
    @hoje = CashEntry.create!(data: Date.new(2026, 10, 9), tipo: "S", categoria: "Despesa", forma_pagamento: "O", valor: 30, descricao: "Água")
  end

  test "lists a period with the balance carried over and totals" do
    get cash_entries_url(inicio: "2026-10-09")
    assert_response :success
    assert_select "td", text: "Água"
    assert_select "td", text: "Troco", count: 0
    assert_select "#caixa-resumo", text: /R\$ 100,00\s*Saldo anterior.*R\$ 70,00\s*Saldo final/m
  end

  test "prints the period summary and an entry's receipt" do
    get cash_entries_url(inicio: "2026-10-08", fim: "2026-10-09", format: :pdf)
    assert_equal "application/pdf", response.media_type
    get recibo_cash_entry_url(@ontem, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "creates, edits and deletes a typed-in entry" do
    assert_difference("CashEntry.count") do
      post cash_entries_url, params: { cash_entry: { data: "2026-10-09", tipo: "E", categoria: "Suprimento", forma_pagamento: "D",
                                                     valor: "50", descricao: "Reforço" } }
    end
    assert_equal users(:one).email, CashEntry.last.usuario
    assert_redirected_to cash_entries_url(inicio: Date.new(2026, 10, 9))

    patch cash_entry_url(@hoje), params: { cash_entry: { valor: "35" } }
    assert_equal 35, @hoje.reload.valor

    assert_difference("CashEntry.count", -1) { delete cash_entry_url(@hoje) }
  end

  test "an entry made by a passenger payment is changed only from there" do
    item = sorders(:one).sorder_items.create!(snomepax: "Ana", amount: 100)
    entrada = item.pagamentos.create!(data: Date.current, valor: 40, forma_pagamento: "D").cash_entry

    get edit_cash_entry_url(entrada)
    assert_redirected_to cash_entries_url(inicio: entrada.data)
    assert_no_difference("CashEntry.count") { delete cash_entry_url(entrada) }
  end

  test "shows validation errors" do
    post cash_entries_url, params: { cash_entry: { data: "", tipo: "E", categoria: "Outros", forma_pagamento: "D", valor: "", descricao: "" } }
    assert_response :unprocessable_entity
    assert_select "#error_explanation li", text: "Descrição não pode ficar em branco"
  end
end
