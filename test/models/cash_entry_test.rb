require 'test_helper'

class CashEntryTest < ActiveSupport::TestCase
  test "balance is entries in minus exits" do
    CashEntry.create!(data: Date.current, tipo: "E", categoria: "Suprimento", forma_pagamento: "D", valor: 100, descricao: "Troco")
    CashEntry.create!(data: Date.current, tipo: "S", categoria: "Despesa", forma_pagamento: "D", valor: 30.5, descricao: "Água")
    assert_equal 69.5, CashEntry.saldo
  end

  test "validates type, method and a positive value" do
    lancamento = CashEntry.new(data: Date.current, tipo: "X", categoria: "Outros", forma_pagamento: "Z", valor: 0, descricao: "x")
    assert_not lancamento.valid?
    assert_equal %i[tipo forma_pagamento valor], lancamento.errors.attribute_names
  end
end
