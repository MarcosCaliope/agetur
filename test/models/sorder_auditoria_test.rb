require 'test_helper'

class SorderAuditoriaTest < ActiveSupport::TestCase
  setup do
    Current.usuario = "ana@agetur.com"
    @ordem = sorders(:one)
  end

  def historico(ordem = @ordem)
    ordem.auditorias.map { |a| [a.registro_type, a.acao, a.descricao, a.alteracoes] }
  end

  test "records what changed on the order, by whom, and names closing and reopening" do
    @ordem.update!(sobservacoes: "Saída às 8h", valorguia: 80)
    @ordem.update!(sobservacoes: "Saída às 8h") # nothing changed
    @ordem.encerrar!
    @ordem.reabrir!

    assert_equal [["Sorder", "alterou", nil, { "sobservacoes" => ["MyString", "Saída às 8h"], "valorguia" => [nil, 80.0] }],
                  ["Sorder", "encerrou", nil, { "encerrada" => [false, true] }],
                  ["Sorder", "reabriu", nil, { "encerrada" => [true, false] }]], historico
    assert_equal ["ana@agetur.com"], @ordem.auditorias.pluck(:usuario).uniq
    assert_equal [@ordem.company_id], @ordem.auditorias.pluck(:company_id).uniq
  end

  test "records a passenger's creation, changes and deletion with its pax list" do
    item = @ordem.sorder_items.create!(snomepax: "Bia", amount: 100, hour: "08:00")
    item.update!(amount: 120)
    item.companions.create!(snome: "Caio", chd: true)
    SorderAuditoria.delete_all

    item.reload.destroy!

    assert_equal [["SorderItem", "excluiu", "Bia"]], historico.map { |linha| linha.first(3) }
    alteracoes = historico.first.last
    assert_equal [["Bia", nil], [120.0, nil], ["Caio (CHD)", nil]], alteracoes.values_at("snomepax", "amount", "lista_pax")
    assert_not alteracoes.key?("updated_at")
  end

  test "records the creation of an order, a passenger and their pax list" do
    ordem = Sorder.create!(@ordem.attributes.slice("data", "destination_id", "tourguide_id", "driver_id", "vehicle_id"))
    item = ordem.sorder_items.create!(snomepax: "Bia", amount: 100, hour: "08:00")
    item.update!(amount: 120)
    item.companions.create!(snome: "Caio")

    linhas = historico(ordem)
    assert_equal [%w[Sorder criou], %w[SorderItem criou], %w[SorderItem alterou], %w[SorderItemCompanion criou]],
                 linhas.map { |linha| linha.first(2) }
    assert_equal [nil, 100.0], linhas[1].last["amount"]
    assert_equal({ "amount" => [100.0, 120.0] }, linhas[2].last)
    assert_equal ["Bia — Caio", { "snome" => [nil, "Caio"] }], linhas[3].last(2)
  end

  test "records payments and their reversal with the paid amount they moved" do
    item = @ordem.sorder_items.create!(snomepax: "Bia", amount: 300, amountpay: 50)
    SorderAuditoria.delete_all

    pagamento = item.pagamentos.create!(data: Date.new(2026, 10, 9), valor: 100, forma_pagamento: "O")
    pagamento.destroy!

    assert_equal [["SorderItemPayment", "recebeu", "Bia",
                   { "data" => [nil, "2026-10-09"], "valor" => [nil, 100.0], "forma_pagamento" => [nil, "PIX"], "amountpay" => [50.0, 150.0] }],
                  ["SorderItemPayment", "estornou recebimento", "Bia",
                   { "data" => [nil, "2026-10-09"], "valor" => [nil, 100.0], "forma_pagamento" => [nil, "PIX"], "amountpay" => [150.0, 50.0] }]],
                 historico
  end

  test "records commission payments and their reversal" do
    item = @ordem.sorder_items.create!(snomepax: "Bia", vendor: vendors(:one), amountcomission: 40, amountcomissionpay: 10)
    conta = Payable.de_comissao(item, "comissao_vendedor", vencimento: Date.current)
    conta.save!
    SorderAuditoria.delete_all

    conta.pagar!(data: Date.current, forma_pagamento: "D")
    conta.estornar!

    descricao = "Bia — Comissão de vendedor: #{vendors(:one).sname}"
    assert_equal [["SorderItem", "pagou comissão", descricao, { "amountcomissionpay" => [10.0, 40.0] }],
                  ["SorderItem", "estornou comissão", descricao, { "amountcomissionpay" => [40.0, 10.0] }]], historico
  end

  test "records a booked tour's down payments moving to the passenger" do
    @ordem.update!(data: Time.zone.local(2026, 11, 5, 8))
    SorderAuditoria.delete_all
    booking = Booking.create!(data: Date.new(2026, 10, 9), snome: "Bia", vendor: vendors(:one))
    passeio = booking.items.create!(destination: @ordem.destination, data_passeio: Date.new(2026, 11, 5), valor: 200)
    passeio.pagamentos.create!(data: Date.current, valor: 60, forma_pagamento: "D")
    assert_empty historico, "a down payment without an order isn't in any history"

    passeio.lancar_na_os!(@ordem)

    assert_equal ["SorderItem", "recebeu sinais do agendamento nº #{booking.id}", "Bia",
                  { "sinais_do_agendamento" => [nil, 60.0], "amountpay" => [nil, 60.0] }], historico.last
  end
end
