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

  def admin_signed_in? = true

  test "icone_link shows an icon with the action as tooltip and hidden label" do
    html = icone_link(:excluir, "/vendors/1", method: :delete, data: { confirm: "Tem certeza?" })
    link = Nokogiri::HTML.fragment(html).at("a")
    assert_equal "/vendors/1", link["href"]
    assert_equal "Excluir", link["title"]
    assert_equal "delete", link["data-method"]
    assert_equal "Tem certeza?", link["data-confirm"]
    assert_includes link["class"], "text-danger"
    assert link.at("svg[aria-hidden=true]")
    assert_equal "Excluir", link.at("span.sr-only").text
  end
end
