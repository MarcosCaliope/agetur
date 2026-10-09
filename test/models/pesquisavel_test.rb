require 'test_helper'

class PesquisavelTest < ActiveSupport::TestCase
  setup do
    @rotas = Agency.create!(sname: "CEARÁ ROTAS", short_name: "ROTAS", city: "FORTALEZA", phone: "8533221100")
    @mar = Agency.create!(sname: "MAR AZUL", document: "12.345.678/0001-90", sistger_id: 223)
  end

  test "blank search returns everything" do
    assert_equal Agency.count, Agency.pesquisar("  ").count
  end

  test "matches the configured columns ignoring case and accents" do
    assert_equal [@rotas], Agency.pesquisar("ceara").to_a
    assert_equal [@rotas], Agency.pesquisar("fortaleza").to_a
    assert_equal [@mar], Agency.pesquisar("345.678").to_a
  end

  test "a number also matches the code or the SISTGER code" do
    assert_includes Agency.pesquisar(@rotas.id.to_s), @rotas
    assert_includes Agency.pesquisar("223"), @mar
    assert_includes Agency.pesquisar("3322"), @rotas, "and still matches text such as the phone"
    assert_empty Agency.pesquisar("99999999999999")
  end

  test "LIKE wildcards in the search are taken literally" do
    assert_empty Agency.pesquisar("%")
    assert_empty Agency.pesquisar("_")
  end

  test "each cadastro searches its own columns" do
    Vehicle.create!(license: "OCI6328", brand: "DUCATO", state: states(:two))
    Destination.create!(description: "JERICOACOARA", state: states(:two))
    Customer.create!(nome: "JOSÉ DA SILVA", document: "111.222.333-44")
    assert_equal ["OCI6328"], Vehicle.pesquisar("ducato").pluck(:license)
    assert_equal ["JERICOACOARA"], Destination.pesquisar("jeri").pluck(:description)
    assert_equal ["JOSÉ DA SILVA"], Customer.pesquisar("jose").pluck(:nome)
    assert_equal ["JOSÉ DA SILVA"], Customer.pesquisar("222.333").pluck(:nome)
  end
end
