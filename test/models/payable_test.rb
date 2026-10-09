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

  test "a typed-in bill needs a creditor" do
    conta = Payable.new(tipo: "avulsa", descricao: "Aluguel", valor: 1000, vencimento: Date.current)
    assert_not conta.valid?
    assert_includes conta.errors.full_messages, "Credor não pode ficar em branco"
  end
end
