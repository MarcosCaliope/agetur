require 'test_helper'

class CommissionPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ordem = sorders(:one)
    @ordem.update!(data: Time.zone.local(2026, 10, 5, 8))
    @ana = @ordem.sorder_items.create!(snomepax: "Ana", vendor: vendors(:one), amountcomission: 40, amountcomissionpay: 10,
                                      agency: agencies(:one), amountcomissionrep: 15)
    @bia = @ordem.sorder_items.create!(snomepax: "Bia", vendor: vendors(:one), amountcomission: 20)
    @ordem.sorder_items.create!(snomepax: "Paga", vendor: vendors(:one), amountcomission: 20, amountcomissionpay: 20)
    @ordem.sorder_items.create!(snomepax: "Cancelada", vendor: vendors(:one), amountcomission: 20, scancelado: "S")
  end

  test "lists commissions left to pay by creditor and order date" do
    get pagamento_comissoes_url(inicio: "2026-10-01", fim: "2026-10-31", credor_id: vendors(:one).id)
    assert_response :success
    assert_select "label", text: "Ana"
    assert_select "label", text: "Bia"
    assert_select "label", text: /Paga|Cancelada/, count: 0
    assert_select "tfoot", text: /R\$ 50,00/

    get pagamento_comissoes_url(tipo: "comissao_repasse", inicio: "2026-10-01")
    assert_select "label", text: "Ana"
    assert_select "label", text: "Bia", count: 0

    get pagamento_comissoes_url(inicio: "2026-11-01")
    assert_select "td", text: "Nenhuma comissão a pagar com estes filtros."
  end

  test "pays one passenger from the order form and goes back to it" do
    assert_difference("CashEntry.count") do
      post pagamento_comissoes_url(tipo: "comissao_vendedor", sorder_id: @ordem.id, credor_id: vendors(:one).id, itens: [@ana.id],
                                   data: "2026-10-09", forma_pagamento: "O", retorno: "ordem")
    end
    saida = CashEntry.last
    assert_redirected_to edit_sorder_url(@ordem)
    assert_equal [30, "S", "O", Date.new(2026, 10, 9)], [saida.valor, saida.tipo, saida.forma_pagamento, saida.data]
    assert_equal [40.0, 0.0], [@ana.reload.amountcomissionpay, @bia.reload.amountcomissionpay.to_f]
    follow_redirect!
    assert_select ".alert-success", text: /Comissão de R\$ 30,00 paga a .* e lançada no caixa \(saída nº #{saida.id}\)/
  end

  test "pays the checked commissions and links the creditor's receipt" do
    assert_difference("CashEntry.count") do
      post pagamento_comissoes_url, params: { tipo: "comissao_vendedor", inicio: "2026-10-01", fim: "2026-10-31",
                                              itens: [@ana.id, @bia.id], data: "2026-10-09", forma_pagamento: "D" }
    end
    saida = CashEntry.last
    assert_redirected_to pagamento_comissoes_url(tipo: "comissao_vendedor", inicio: Date.new(2026, 10, 1), fim: Date.new(2026, 10, 31),
                                                 recibos: [saida.id])
    assert_equal [50, "S", users(:one).email], [saida.valor, saida.tipo, saida.usuario]
    assert_equal [40.0, 20.0], [@ana.reload.amountcomissionpay, @bia.reload.amountcomissionpay]

    follow_redirect!
    assert_select ".alert-info a[href='#{recibo_cash_entry_path(saida, format: :pdf)}']"

    get recibo_cash_entry_url(saida, format: :pdf)
    assert_equal "application/pdf", response.media_type
  end

  test "asks to check something" do
    assert_no_difference("CashEntry.count") do
      post pagamento_comissoes_url, params: { inicio: "2026-10-01", data: "2026-10-09", forma_pagamento: "D" }
    end
    follow_redirect!
    assert_select ".alert-danger", text: "Marque ao menos um passageiro."
  end
end
