require "test_helper"

class ResumoOperacionalControllerTest < ActionDispatch::IntegrationTest
  include TextoDoPdf

  setup do
    sign_in users(:one)
    tourguides(:two).update!(sname: "Sandra")
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 10, 5, 8), valorguia: 100, valormotorista: 50, valorpedagio: 20,
                   valorcombustivel: 30, valordespesas: 10)
    @ordem.sorder_items.create!(snomepax: "Ana", amount: 500, discount: 20, vendor_discount: 30, amountcomission: 45)
    @ordem.sorder_items.create!(snomepax: "Bia", amount: 200, amountcomission: 15)
    @ordem.sorder_items.create!(snomepax: "Cancelada", amount: 999, amountcomission: 99, scancelado: "S")
    sorders(:two).update!(data: Time.zone.local(2026, 9, 30, 8))
    @periodo = { inicio: "2026-10-01", fim: "2026-10-31" }
  end

  test "lists each order of the period with its costs, value, commissions and total" do
    get resumo_operacional_url(@periodo)
    assert_response :success
    assert_select "tbody tr", 1
    assert_select "tbody a[href=?]", sorder_path(@ordem), text: @ordem.id.to_s
    assert_select "tbody td div", text: "Sandra"
    linha = css_select("tbody tr td").map { |td| td.text.strip }
    # Guia, motorista, pedágio, combustível, despesas; valor OS (650 less
    # both discounts, cancelled left out), comissões, despesas, total.
    assert_equal ["R$ 100,00", "R$ 50,00", "R$ 20,00", "R$ 30,00", "R$ 10,00", "R$ 650,00", "R$ 60,00", "R$ 210,00", "R$ 380,00"],
                 linha.last(9)
    assert_select "tfoot", text: /1 ordem.*R\$ 380,00/m

    get resumo_operacional_url(inicio: "2026-11-01", fim: "2026-11-30")
    assert_select "td", text: "Nenhuma ordem no período."
  end

  test "a negative total is shown in red" do
    @ordem.update!(valordespesas: 1000)
    get resumo_operacional_url(@periodo)
    assert_select "td.text-danger", text: "-R$ 610,00"
  end

  test "exports the SISTGER layout as PDF with the totals" do
    get resumo_operacional_url(@periodo.merge(format: :pdf))
    assert_equal "application/pdf", response.media_type
    texto = texto_do_pdf(response.body)
    assert_includes texto, "Resumo operacional das ordens de serviço de 01/10/2026 a 31/10/2026"
    assert_includes texto, "Sandra"
    assert_includes texto, "Valor Comissões"
    assert_includes texto, "650,00"
    assert_includes texto, "380,00"
    assert_includes texto, "Valor Total O.S.:"
  end

  test "a user without the route is sent home" do
    sign_out users(:one)
    sign_in users(:consulta)
    get resumo_operacional_url
    assert_redirected_to root_url
  end
end
