require 'test_helper'

class SorderTest < ActiveSupport::TestCase
  test "total_pax and total_chd ignore cancelled passengers" do
    sorder = sorders(:one)
    sorder.sorder_items.create!(qtdepax: 2, qtdechd: 1, scancelado: "N")
    sorder.sorder_items.create!(qtdepax: 3, qtdechd: 0)
    sorder.sorder_items.create!(qtdepax: 4, qtdechd: 2, scancelado: "S")

    assert_equal 5, sorder.total_pax
    assert_equal 1, sorder.total_chd
  end

  test "removing a saved passenger in the form cancels it; a new row is just dropped" do
    Current.usuario = "ana@agetur.com"
    sorder = sorders(:one)
    item = sorder.sorder_items.create!(snomepax: "Bia", amount: 100)
    item.pagamentos.create!(data: Date.current, valor: 30, forma_pagamento: "D")

    assert_no_difference(["SorderItem.count", "SorderItemPayment.count", "CashEntry.count"]) do
      sorder.update!(sorder_items_attributes: { "0" => { id: item.id.to_s, _destroy: "1" }, "1" => { snomepax: "Nova", _destroy: "1" } })
    end

    assert item.reload.cancelado?
    assert_equal [30.0], [item.amountpay]
    assert_equal ["cancelou", { "scancelado" => [nil, "S"] }], sorder.auditorias.last.then { |a| [a.acao, a.alteracoes] }

    item.update!(scancelado: "N")
    assert_equal "reativou", sorder.auditorias.last.acao
  end
end
