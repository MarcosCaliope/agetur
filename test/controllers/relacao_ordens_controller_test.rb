require "test_helper"

class RelacaoOrdensControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    vendors(:one).update!(sname: "Vendedor Um")
    vendors(:two).update!(sname: "Vendedor Dois")
    destinations(:one).update!(description: "Arraial")
    destinations(:two).update!(description: "Buzios")

    @buzios = sorders(:one)
    @buzios.update!(data: Time.zone.local(2026, 10, 5, 8))
    @arraial = sorders(:two)
    @arraial.update!(data: Time.zone.local(2026, 10, 6, 8), destination: destinations(:one))
    @ana = @buzios.sorder_items.create!(snomepax: "Ana", vendor: vendors(:one), qtdepax: 2, qtdechd: 1, amount: 100, amountpay: 40,
                                        amountcomission: 10)
    @buzios.sorder_items.create!(snomepax: "Bia", vendor: vendors(:two), qtdepax: 1, amount: 50, amountcomission: 5)
    @buzios.sorder_items.create!(snomepax: "Cancelada", vendor: vendors(:one), qtdepax: 3, amount: 70, scancelado: "S")
    @arraial.sorder_items.create!(snomepax: "Caio", vendor: vendors(:one), qtdepax: 1, amount: 80, amountpay: 80, amountcomission: 8)
    @periodo = { inicio: "2026-10-01", fim: "2026-10-31" }
  end

  # Prawn writes each line as hex strings split by kerning: [<4d79> -15 <537472>] TJ.
  def texto_do_pdf(pdf)
    pdf.b.scan(/\[(.*?)\] TJ/).map do |(partes)|
      partes.scan(/<(\h*)>/).map { |(hex)| [hex].pack("H*") }.join.force_encoding("Windows-1252").encode("UTF-8")
    end.join("\n")
  end

  test "lists one line per order in the period, with totals that leave cancelled passengers out" do
    get relacao_ordens_url(@periodo)
    assert_response :success
    assert_select "tbody tr", 2
    assert_select "tbody a[href=?]", sorder_path(@buzios), text: @buzios.id.to_s
    assert_select "tbody tr:first-child td", text: "Buzios"
    assert_select "tbody tr:first-child td", text: "R$ 150,00"
    assert_select "tfoot th", text: /2 ordens/
    assert_select "tfoot td", text: "R$ 230,00"
    assert_select "tfoot td", text: "R$ 110,00" # a receber: 60 + 50 + 0

    get relacao_ordens_url(inicio: "2026-11-01", fim: "2026-11-30")
    assert_select "td", text: "Nenhuma ordem com estes filtros."
  end

  test "filters by roteiro and vendor" do
    get relacao_ordens_url(@periodo.merge(destination_id: destinations(:two).id, modo: "analitico"))
    assert_select "tbody td", text: "Ana"
    assert_select "tbody td", text: "Caio", count: 0
    assert_select "tbody td", text: /Cancelada/, count: 0
    assert_select "p.text-muted", text: "Roteiro: Buzios"

    get relacao_ordens_url(@periodo.merge(vendor_id: vendors(:one).id, modo: "analitico"))
    assert_select "tbody td", text: "Ana"
    assert_select "tbody td", text: "Caio"
    assert_select "tbody td", text: "Bia", count: 0
  end

  test "groups passengers by vendor with subtotals and shows cancelled ones on request" do
    get relacao_ordens_url(@periodo.merge(agrupar: "vendedor", modo: "analitico", cancelados: "1"))
    titulos = css_select("tr.table-secondary th").map(&:text)
    assert_equal ["Vendedor: Vendedor Dois", "Vendedor: Vendedor Um", "Vendedor: Sem vendedor"], titulos
    assert_select "tbody td", text: "Cancelada (cancelado)"
    assert_select "tr.font-weight-bold", text: /Subtotal Vendedor Um.*R\$ 180,00/m
    assert_select "tfoot td", text: "R$ 230,00"
  end

  test "filters closed orders" do
    @arraial.update_columns(encerrada: true)
    get relacao_ordens_url(@periodo.merge(situacao: "encerradas"))
    assert_select "tbody tr", 1
    assert_select "tbody td", text: "Arraial"
  end

  test "exports the same report as PDF" do
    get relacao_ordens_url(@periodo.merge(agrupar: "roteiro", modo: "analitico", format: :pdf))
    assert_response :success
    assert_equal "application/pdf", response.media_type
    texto = texto_do_pdf(response.body)
    assert_includes texto, "Roteiro: Arraial"
    assert_includes texto, "Subtotal Buzios"
    assert_includes texto, "Ana"
    assert_includes texto, "Total: 2 ordens"
  end

  test "a user without the route is sent home" do
    sign_out users(:one)
    sign_in users(:consulta)
    get relacao_ordens_url
    assert_redirected_to root_url
  end
end
