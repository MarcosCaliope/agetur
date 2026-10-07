require 'test_helper'

class SorderItemTest < ActiveSupport::TestCase
  setup do
    @sorder = sorders(:two)
  end

  test "total_receber subtracts commission already received" do
    item = SorderItem.new(amountcomission: 30.0, amountcomissionpay: 10.0)
    assert_equal 20.0, item.total_receber
  end

  test "total_receber and total_passeio treat blank values as zero" do
    assert_equal 30.0, SorderItem.new(amountcomission: 30.0).total_receber
    assert_equal 0.0, SorderItem.new.total_receber
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

  test "nome_passageiro prefers the typed name and falls back to the customer" do
    assert_equal "Maria", SorderItem.new(snomepax: "Maria", customer: customers(:one)).nome_passageiro
    assert_equal customers(:one).nome, SorderItem.new(customer: customers(:one)).nome_passageiro
  end
end
