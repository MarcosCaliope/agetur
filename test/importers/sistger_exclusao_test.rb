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

  test "agendamentos deletes the company's bookings with their tours and down payments" do
    booking = Booking.create!(data: Date.current, snome: "Ana", vendor: vendors(:two), hotel: hotels(:two))
    tour = booking.items.create!(destination: destinations(:two), data_passeio: Date.current, valor: 10)
    vendedor_da_outra = Vendor.unscoped.create!(sname: "VENDEDOR DA OUTRA", company_id: @outra.id)
    da_outra = Current.set(empresa_id: @outra.id) do
      Booking.create!(data: Date.current, snome: "Bia", vendor: vendedor_da_outra, hotel: @hotel_da_outra)
    end

    resultado = @exclusao.excluir(%w[agendamentos]).first

    assert_equal "Agendamentos", resultado.etapa.nome
    assert_equal 0, Booking.unscoped.where(company_id: @empresa.id).count
    assert_not BookingItem.unscoped.exists?(tour.id)
    assert Booking.unscoped.exists?(da_outra.id)
  end

  test "bookings are what kept hotels from being deleted" do
    Booking.create!(data: Date.current, snome: "Ana", vendor: vendors(:two), hotel: hotels(:two))
    erro = assert_raises(SistgerExclusao::Erro) { @exclusao.excluir(%w[ordens hoteis]) }
    assert_match(/agendamentos/i, erro.message)
  end

  test "refuses tours placed in orders that stay, but not when the orders go too" do
    item = sorder_items(:two)
    booking = Booking.create!(data: Date.current, snome: "Ana", vendor: vendors(:two), hotel: hotels(:two))
    booking.items.create!(destination: destinations(:two), data_passeio: Date.current, valor: 10).update_columns(sorder_item_id: item.id)

    erro = assert_raises(SistgerExclusao::Erro) { @exclusao.excluir(%w[agendamentos]) }
    assert_match(/já estão em ordens/, erro.message)
    assert Booking.unscoped.exists?(booking.id)

    @exclusao.excluir(%w[ordens agendamentos])
    assert_not Booking.unscoped.exists?(booking.id)
    assert_not Sorder.unscoped.exists?(item.sorder_id)
  end

  test "deletes every table of the company, imported or not, and nothing of another company" do
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
