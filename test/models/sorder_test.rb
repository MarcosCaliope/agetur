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

  test "orders are numbered per company, and a typed number finds the current company's order" do
    atributos = sorders(:one).attributes.except("id", "numero", "company_id", "sistger_id")
    assert_equal 3, Sorder.create!(atributos).numero, "company :two already has orders 1 and 2"

    outra = Company.create!(name: "OUTRA", state: states(:two))
    ordem_da_outra = Current.set(empresa_id: outra.id, filtrar_empresa: true) do
      Sorder.create!(atributos.merge(destination_id: nil, tourguide_id: nil, driver_id: nil, vehicle_id: nil).merge(
        destination: Destination.unscoped.create!(description: "X", state: states(:two), company: outra),
        tourguide: Tourguide.unscoped.create!(sname: "G", company: outra), driver: Driver.unscoped.create!(sname: "M", company: outra),
        vehicle: Vehicle.unscoped.create!(license: "P", state: states(:two), company: outra)
      ))
    end
    assert_equal 1, ordem_da_outra.numero, "each company starts at 1"

    Current.set(filtrar_empresa: true) do
      assert_equal sorders(:one), Sorder.do_numero(" 1 ")
      assert_equal sorders(:two), Sorder.do_numero("2")
      assert_nil Sorder.do_numero("4")
      assert_nil Sorder.do_numero("")
    end
    Current.set(empresa_id: outra.id, filtrar_empresa: true) { assert_equal ordem_da_outra, Sorder.do_numero("1") }
  end
end
