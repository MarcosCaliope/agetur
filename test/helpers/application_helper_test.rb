require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "ultimo_registro shows the highest-numbered record with its name and SISTGER code" do
    Customer.create!(nome: "PRIMEIRO")
    ultimo = Customer.create!(nome: "MARIA", sistger_id: 1234)
    html = ultimo_registro(Customer)
    assert_includes html, "Último registro: nº #{number_with_delimiter(ultimo.id)} — MARIA (código SISTGER 1.234)"
  end

  test "ultimo_registro describes service orders by date and destination" do
    ordem = sorders(:one).dup.tap { |o| o.data = Time.utc(2026, 6, 16); o.save! }
    assert_includes ultimo_registro(Sorder), "nº #{number_with_delimiter(ordem.id)} — 16/06/2026 — #{ordem.destination.description}"
  end

  test "ultimo_registro says when there are none" do
    Vendor.delete_all
    assert_includes ultimo_registro(Vendor), "Último registro: nenhum"
  end
end
