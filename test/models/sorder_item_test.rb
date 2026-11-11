require 'test_helper'

class SorderItemTest < ActiveSupport::TestCase
  setup do
    @sorder = sorders(:two)
  end

  test "changing the pax list recounts PAX and CHD, colo doesn't count" do
    item = @sorder.sorder_items.create!(snomepax: "Titular", qtdepax: 4, qtdechd: 1)
    assert_equal [4, 1], [item.qtdepax, item.qtdechd], "without a list the typed quantities stay"

    item.update!(companions_attributes: [{ snome: "Adulto" }, { snome: "Criança", chd: true }, { snome: "Bebê", chd: true, colo: true }])
    assert_equal [2, 1], [item.reload.qtdepax, item.qtdechd]

    item.update!(qtdepax: 5, comments: "obs")
    assert_equal 5, item.reload.qtdepax, "a save that doesn't touch the list keeps the typed quantity"

    crianca = item.companions.find_by!(snome: "Criança")
    item.update!(companions_attributes: [{ id: crianca.id, snome: "Criança", chd: false }])
    assert_equal [3, 0], [item.reload.qtdepax, item.qtdechd]

    item.update!(companions_attributes: item.companions.map { |pessoa| { id: pessoa.id, _destroy: "1" } })
    assert_equal [1, 0], [item.reload.qtdepax, item.qtdechd]
  end

  test "comissao_a_pagar subtracts commission already paid" do
    item = SorderItem.new(amountcomission: 30.0, amountcomissionpay: 10.0)
    assert_equal 20.0, item.comissao_a_pagar
  end

  test "comissao_a_pagar and total_passeio treat blank values as zero" do
    assert_equal 30.0, SorderItem.new(amountcomission: 30.0).comissao_a_pagar
    assert_equal 0.0, SorderItem.new.comissao_a_pagar
    assert_equal 100.0, SorderItem.new(amount: 100.0).total_passeio
    assert_equal 60.0, SorderItem.new(amount: 100.0, amountpay: 40.0).total_passeio
  end

  test "ativos excludes only cancelled items" do
    ativo = @sorder.sorder_items.create!(scancelado: "N")
    antigo = @sorder.sorder_items.create!(scancelado: nil)
    cancelado = @sorder.sorder_items.create!(scancelado: "S")

    ativos = SorderItem.ativos
    assert_includes ativos, ativo
    assert_includes ativos, antigo
    assert_not_includes ativos, cancelado
    assert cancelado.cancelado?
  end

  test "an inactive vendor can't be chosen, but items already using one stay editable" do
    inativo = vendors(:one).tap { |v| v.update!(active: false) }
    novo = @sorder.sorder_items.build(vendor: inativo)
    assert_not novo.valid?
    assert_includes novo.errors[:vendor], "está inativo"

    SorderItem.where(id: (antigo = @sorder.sorder_items.create!).id).update_all(vendor_id: inativo.id)
    antigo.reload.comments = "editado"
    assert antigo.valid?
  end

  test "nome_passageiro prefers the typed name and falls back to the customer" do
    assert_equal "Maria", SorderItem.new(snomepax: "Maria", customer: customers(:one)).nome_passageiro
    assert_equal customers(:one).nome, SorderItem.new(customer: customers(:one)).nome_passageiro
  end

  test "records the signed-in account that creates it, unless one is given" do
    Current.usuario = "ana@example.com"
    assert_equal "ana@example.com", sorders(:one).sorder_items.create!(snomepax: "Bia").usuario
    assert_equal "caio@example.com", sorders(:one).sorder_items.create!(snomepax: "Caio", usuario: "caio@example.com").usuario
  end
  test "transferring moves the passenger with its pax list and payments, and notes it" do
    origem = sorders(:two)
    destino = sorders(:one)
    item = origem.sorder_items.create!(snomepax: "Maria", amount: 100, comments: "Janela",
                                       sistger_numero: 900, sistger_sequencial: 1,
                                       companions_attributes: [{ snome: "Filho", chd: true }])
    pagamento = item.pagamentos.create!(data: Date.current, valor: 40, forma_pagamento: "D")
    versao = origem.reload.lock_version

    item.transferir_para!(destino)

    item.reload
    assert_equal destino.id, item.sorder_id
    assert_equal "Janela Transferido da OS nº #{origem.numero} em #{I18n.l(Date.current)}.", item.comments
    assert_equal 40, item.amountpay
    assert_equal ["Filho"], item.companions.map(&:snome)
    assert_equal destino.id, pagamento.cash_entry.reload.sorder_id
    assert_nil item.sistger_numero, "a re-import of the old order mustn't move it back"
    assert_operator origem.reload.lock_version, :>, versao
    [origem, destino].each do |ordem|
      assert ordem.auditorias.exists?(acao: "transferiu", registro: item, alteracoes: { "sorder_id" => [origem.id, destino.id] })
    end
  end

  test "copying places a new passenger with the pax list but nothing received, and notes it in both" do
    origem = sorders(:two)
    destino = sorders(:one)
    item = origem.sorder_items.create!(snomepax: "Maria", amount: 100, amountcomission: 10, amountcomissionpay: 10,
                                       qtdepax: 3, companions_attributes: [{ snome: "Filho", chd: true }])
    item.update_columns(qtdepax: 3, qtdechd: 0)
    item.pagamentos.create!(data: Date.current, valor: 40, forma_pagamento: "D")

    copia = assert_difference("SorderItem.count") { item.copiar_para!(destino) }

    data = I18n.l(Date.current)
    assert_equal destino.id, copia.sorder_id
    assert_equal ["Maria", 100, 10], [copia.snomepax, copia.amount, copia.amountcomission]
    assert_equal [0, 0], [copia.amountpay.to_f, copia.amountcomissionpay.to_f]
    assert_equal [3, 0], [copia.qtdepax, copia.qtdechd], "keeps the original's PAX/CHD"
    assert_equal ["Filho"], copia.companions.map(&:snome)
    assert_empty copia.pagamentos
    assert_equal "Copiado da OS nº #{origem.numero} em #{data}.", copia.comments
    assert_equal "Copiado para a OS nº #{destino.numero} em #{data}.", item.reload.comments
    assert_equal origem.id, item.sorder_id
    assert_equal ["Filho"], item.companions.map(&:snome)
  end

  test "transfers and copies need another open order and an active passenger" do
    item = sorder_items(:one)
    destino = sorders(:one)
    erro = ->(destino) { assert_raises(SorderItem::NaoMovimentado) { item.transferir_para!(destino) }.message }

    assert_equal "OS de destino não encontrada.", erro.(nil)
    assert_equal "Escolha uma OS diferente da atual.", erro.(item.sorder)
    destino.update!(encerrada: true)
    assert_equal "A OS nº #{destino.numero} está encerrada.", erro.(destino)
    destino.update!(encerrada: false)
    item.update!(scancelado: "S")
    assert_equal "Passageiro cancelado: reative-o antes.", erro.(destino)
    assert_raises(SorderItem::NaoMovimentado) { item.copiar_para!(destino) }
    assert_equal sorders(:two).id, item.reload.sorder_id
  end
end
