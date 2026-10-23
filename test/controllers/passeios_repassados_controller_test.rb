require "test_helper"

class PasseiosRepassadosControllerTest < ActionDispatch::IntegrationTest
  include TextoDoPdf

  setup do
    sign_in users(:one)
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 10, 5, 8))
    sorders(:two).update!(data: Time.zone.local(2026, 9, 30, 8))
    agencies(:one).update!(sname: "Brisa Turismo")
    agencies(:two).update!(sname: "Atlântica")
    hotels(:one).update!(sname: "Praiano")
    @ordem.sorder_items.create!(snomepax: "Ana", agency: agencies(:one), hotel: hotels(:one), apto: "12", amount: 100,
                                amountpay: 30, amountcomissionrep: 20, amountcomissionreppay: 5)
    @ordem.sorder_items.create!(snomepax: "Bia", agency: agencies(:one), amount: 50, amountcomissionrep: 10)
    @ordem.sorder_items.create!(snomepax: "Caio", agency: agencies(:two), amount: 80, amountcomissionrep: 8,
                                amountcomissionreppay: 8)
    @ordem.sorder_items.create!(snomepax: "Cancelada", agency: agencies(:two), amount: 999, scancelado: "S")
    @ordem.sorder_items.create!(snomepax: "Sem repasse", amount: 70)
    sorders(:two).sorder_items.create!(snomepax: "Fora", agency: agencies(:one), amount: 40)
    @periodo = { inicio: "2026-10-01", fim: "2026-10-31" }
  end

  test "groups the period's passed-on passengers by agency, with each agency's totals" do
    get passeios_repassados_url(@periodo)
    assert_response :success
    assert_equal ["Atlântica", "Brisa Turismo"], css_select("tr.table-secondary th").map(&:text)
    assert_select "tbody td", text: "Praiano / 12"
    assert_select "tbody td", text: /Fora|Cancelada|Sem repasse/, count: 0
    assert_select "tbody tr.font-weight-bold", text: /Total da agência: 2 passageiros.*R\$ 120,00.*R\$ 30,00.*R\$ 5,00.*R\$ 25,00/m
    assert_select "tfoot tr", text: /Total geral: 3 passageiros.*R\$ 200,00.*R\$ 38,00.*R\$ 13,00.*R\$ 25,00/m
  end

  test "filters by agency and shows cancelled passengers on request, outside the totals" do
    get passeios_repassados_url(@periodo.merge(agencia_id: agencies(:two).id, cancelados: "1"))
    assert_equal ["Atlântica"], css_select("tr.table-secondary th").map(&:text)
    assert_select "h5", text: /Atlântica/
    assert_select "tbody td", text: "Cancelada (cancelado)"
    assert_select "tfoot tr", text: /Total geral: 1 passageiro.*R\$ 80,00/m
  end

  test "exports it as PDF" do
    get passeios_repassados_url(@periodo.merge(format: :pdf))
    assert_equal "application/pdf", response.media_type
    texto = texto_do_pdf(response.body)
    assert_includes texto, "Passeios repassados de 01/10/2026 a 31/10/2026"
    assert_includes texto, "Brisa Turismo"
    assert_includes texto, "Total da agência: 2 passageiro(s)"
    assert_includes texto, "Total geral: 3 passageiro(s)"
  end

  test "a user without the route is sent home" do
    sign_out users(:one)
    sign_in users(:consulta)
    get passeios_repassados_url
    assert_redirected_to root_url
  end
end
