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
end
