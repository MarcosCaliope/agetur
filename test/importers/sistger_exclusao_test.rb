require 'test_helper'

class SistgerExclusaoTest < ActiveSupport::TestCase
  setup do
    @empresa = companies(:two)
    @exclusao = SistgerExclusao.new(@empresa.id)
    @outra = Company.create!(name: "OUTRA", state: states(:two))
    @hotel_da_outra = Hotel.unscoped.create!(sname: "HOTEL DA OUTRA", company_id: @outra.id)
  end

  test "contagens counts the company's records of each step" do
    contagens = @exclusao.contagens(%w[hoteis ordens])
    assert_equal({ "ordens" => Sorder.unscoped.where(company_id: @empresa.id).count,
                   "hoteis" => Hotel.unscoped.where(company_id: @empresa.id).count }, contagens, "dependents first")
    assert_equal %w[ordens hoteis], contagens.keys, "dependents first"
  end

  test "refuses, deleting nothing, while records that stay use the ones it would delete" do
    sorder_items(:two).update_columns(hotel_id: hotels(:two).id)
    caixa = CashEntry.create!(data: Date.current, descricao: "TESTE", categoria: "Outros", valor: 10, tipo: "E", forma_pagamento: "D")
    erro = assert_raises(SistgerExclusao::Erro) { @exclusao.excluir(%w[caixa hoteis]) }
    assert_match(/Hotéis: ainda em uso por .*passageiros/i, erro.message)
    assert CashEntry.unscoped.exists?(caixa.id), "the caixa deleted before the refusal is rolled back"
    assert Hotel.unscoped.exists?(hotels(:two).id)
  end

  test "refuses orders holding booked tours" do
    item = sorder_items(:two)
    booking = Booking.create!(data: Date.current, snome: "Ana", vendor: vendors(:two), hotel: hotels(:two))
    booking.items.create!(destination: destinations(:two), data_passeio: Date.current, valor: 10).update_columns(sorder_item_id: item.id)
    erro = assert_raises(SistgerExclusao::Erro) { @exclusao.excluir(%w[ordens]) }
    assert_match(/passeio\(s\) agendado/, erro.message)
    assert Sorder.exists?(item.sorder_id)
  end

  test "deletes every table of the company, imported or not, and nothing of another company" do
    Booking.unscoped.where(company_id: @empresa.id).destroy_all
    User.where(vendor_id: Vendor.select(:id)).update_all(vendor_id: nil)
    SorderAuditoria.create!(sorder_id: Sorder.first.id, registro_type: "Sorder", acao: "criou", company_id: @empresa.id)

    resultados = @exclusao.excluir(SistgerExclusao::EXCLUSAO.reverse)

    assert_equal SistgerExclusao::EXCLUSAO, resultados.map { |r| r.etapa.chave }
    SistgerExclusao::EXCLUSAO.each { |chave| assert_equal 0, @exclusao.contagens([chave])[chave], chave }
    assert_equal 0, SorderItem.unscoped.where(company_id: @empresa.id).count
    assert_equal 0, SorderAuditoria.unscoped.where(company_id: @empresa.id).count
    assert Hotel.unscoped.exists?(@hotel_da_outra.id)
    assert Company.exists?(@empresa.id), "the company itself stays"
  end

  test "unknown steps are refused" do
    assert_raises(SistgerExclusao::Erro) { @exclusao.excluir(%w[empresa]) }
    assert_raises(SistgerExclusao::Erro) { @exclusao.contagens(%w[nada]) }
  end
end
