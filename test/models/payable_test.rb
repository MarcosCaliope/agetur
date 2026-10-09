require 'test_helper'

class PayableTest < ActiveSupport::TestCase
  setup do
    @ordem = sorders(:one)
    @ordem.update!(valorguia: 80, valormotorista: 0, valorpedagio: 12.5)
    @item = @ordem.sorder_items.create!(snomepax: "Ana", vendor: vendors(:one), amountcomission: 40, amountcomissionpay: 10,
                                        agency: agencies(:one), amountcomissionrep: 20, amountcomissionreppay: 20)
    @ordem.sorder_items.create!(snomepax: "Cancelado", vendor: vendors(:one), amountcomission: 99, scancelado: "S")
  end

  test "closing an order turns its unpaid commissions and costs into bills due on the order date" do
    @ordem.encerrar!

    assert @ordem.reload.encerrada?
    contas = @ordem.payables.order(:tipo, :origem).map { |c| [c.tipo, c.origem, c.valor.to_f, c.nome_credor, c.vencimento] }
    vencimento = @ordem.data.to_date
    assert_equal [["comissao_vendedor", "vendedor", 30.0, vendors(:one).sname, vencimento],
                  ["custo_os", "guia", 80.0, @ordem.tourguide.sname, vencimento],
                  ["custo_os", "pedagio", 12.5, "Pedágio", vencimento]], contas
    assert_equal "Comissão OS #{@ordem.id} PAX Ana", @ordem.payables.find_by!(origem: "vendedor").descricao

    assert_no_difference("Payable.count") { @ordem.encerrar! }
  end

  test "vendors that aren't paid commission get no bill" do
    vendors(:one).update!(no_commission: true)
    @ordem.encerrar!
    assert_not @ordem.payables.exists?(tipo: "comissao_vendedor")
  end

  test "paying a commission posts a cash exit and counts as paid on the passenger; reversing undoes both" do
    @ordem.encerrar!
    comissao = @ordem.payables.find_by!(origem: "vendedor")

    comissao.pagar!(data: Date.new(2026, 10, 9), forma_pagamento: "O", usuario: "a@b.c")
    saida = comissao.cash_entry
    assert_equal ["S", 30, "Pagamento de conta", "Pagamento: #{comissao.descricao}", vendors(:one).sname],
                 [saida.tipo, saida.valor, saida.categoria, saida.descricao, saida.requerente]
    assert_equal [Date.new(2026, 10, 9), 30], [comissao.pago_em, comissao.valor_pago]
    assert_equal 40.0, @item.reload.amountcomissionpay

    assert_difference("CashEntry.count", -1) { comissao.estornar! }
    assert_not comissao.reload.pago?
    assert_equal 10.0, @item.reload.amountcomissionpay
  end

  test "reopening drops the unpaid bills of the close and keeps paid ones" do
    @ordem.encerrar!
    @ordem.payables.find_by!(origem: "guia").pagar!(data: Date.current, forma_pagamento: "D")

    @ordem.reabrir!
    assert_not @ordem.reload.encerrada?
    assert_equal ["guia"], @ordem.payables.pluck(:origem)

    @ordem.encerrar!
    assert_equal %w[guia pedagio vendedor], @ordem.payables.order(:origem).pluck(:origem), "the paid one isn't made again"
  end

  test "pays commissions in a batch with one cash exit per creditor; reversing one undoes its batch" do
    outro = Vendor.create!(sname: "OUTRO", active: true)
    item2 = @ordem.sorder_items.create!(snomepax: "Bruno", vendor: vendors(:one), amountcomission: 25)
    item3 = @ordem.sorder_items.create!(snomepax: "Caio", vendor: outro, amountcomission: 5)
    contas = [@item, item2, item3].map { |i| Payable.de_comissao(i, "comissao_vendedor", vencimento: Date.current).tap(&:save!) }

    saidas = Payable.pagar_em_lote!(contas, data: Date.new(2026, 10, 9), forma_pagamento: "O", usuario: "a@b.c")

    assert_equal [[vendors(:one).sname, 55], ["OUTRO", 5]], saidas.map { |s| [s.requerente, s.valor] }
    assert_equal "Pagamento de comissões a #{vendors(:one).sname}: 2 passageiro(s) - OS #{@ordem.id}", saidas.first.descricao
    assert_equal [40.0, 25.0, 5.0], [@item, item2, item3].map { |i| i.reload.amountcomissionpay }
    assert_equal 1, contas.first.reload.lote.count

    assert_difference("CashEntry.count", -1) { contas.second.reload.estornar! }
    assert_equal [false, false, true], contas.map { |c| c.reload.pago? }
    assert_equal [10.0, 0.0, 5.0], [@item, item2, item3].map { |i| i.reload.amountcomissionpay }
  end

  test "an open bill is reused, and what's added after a payment gets a new one" do
    @ordem.encerrar!
    aberta = @ordem.payables.find_by!(origem: "vendedor")
    assert_equal aberta, Payable.de_comissao(@item, "comissao_vendedor", vencimento: Date.current)

    aberta.pagar!(data: Date.current, forma_pagamento: "D")
    assert_nil Payable.de_comissao(@item.reload, "comissao_vendedor", vencimento: Date.current), "nothing left to pay"

    @ordem.reabrir!
    @item.update!(amountcomission: 50)
    @ordem.encerrar!
    assert_equal [[30.0, true], [10.0, false]], @ordem.payables.where(origem: "vendedor").order(:id).map { |c| [c.valor.to_f, c.pago?] }
  end

  test "closing again brings an open bill up to date" do
    @ordem.encerrar!
    @ordem.update_columns(valorguia: 100)
    @ordem.encerrar!
    assert_equal [100.0], @ordem.payables.where(origem: "guia").map { |c| c.valor.to_f }
  end

  test "a typed-in bill needs a creditor" do
    conta = Payable.new(tipo: "avulsa", descricao: "Aluguel", valor: 1000, vencimento: Date.current)
    assert_not conta.valid?
    assert_includes conta.errors.full_messages, "Credor não pode ficar em branco"
  end
end
