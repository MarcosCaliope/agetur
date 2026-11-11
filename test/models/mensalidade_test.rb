require 'test_helper'

class MensalidadeTest < ActiveSupport::TestCase
  setup do
    @company = companies(:two)
    @company.update!(mensalidade_valor: 150, dia_vencimento: 10, dias_tolerancia: 5, acesso_liberado_ate: nil)
  end

  def pagar(referencia, **atributos)
    @company.mensalidades.create!(referencia: referencia, valor: 150, pago_em: Date.new(2026, 11, 8), **atributos)
  end

  test "paying a month frees access until next month's due day plus the grace days" do
    mensalidade = pagar(Date.new(2026, 11, 20))
    assert_equal Date.new(2026, 11, 1), mensalidade.referencia, "kept as the month's 1st"
    assert_equal Date.new(2026, 12, 15), @company.reload.acesso_liberado_ate
  end

  test "the due day falls on the month's last day in shorter months" do
    @company.update!(dia_vencimento: 31, dias_tolerancia: 0)
    assert_equal Date.new(2027, 2, 28), @company.acesso_pago_ate(Date.new(2027, 1, 1))
    assert_equal Date.new(2027, 3, 31), @company.acesso_pago_ate(Date.new(2027, 2, 1))
  end

  test "paying never moves access backwards, so a longer trial survives" do
    @company.update!(acesso_liberado_ate: Date.new(2027, 3, 1))
    pagar(Date.new(2026, 11, 1))
    assert_equal Date.new(2027, 3, 1), @company.reload.acesso_liberado_ate
  end

  test "deleting a payment recomputes access from the latest month still paid" do
    pagar(Date.new(2026, 11, 1))
    dezembro = pagar(Date.new(2026, 12, 1))
    assert_equal Date.new(2027, 1, 15), @company.reload.acesso_liberado_ate

    dezembro.destroy!
    assert_equal Date.new(2026, 12, 15), @company.reload.acesso_liberado_ate
    assert_equal Date.new(2026, 12, 1), @company.proxima_referencia
  end

  test "a month is paid once, and the company needs a due day" do
    pagar(Date.new(2026, 11, 1))
    repetida = @company.mensalidades.new(referencia: Date.new(2026, 11, 15), valor: 150, pago_em: Date.current)
    assert_not repetida.valid?
    assert_includes repetida.errors[:referencia], "já tem pagamento registrado"

    outra = companies(:one)
    sem_vencimento = outra.mensalidades.new(referencia: Date.new(2026, 11, 1), valor: 150, pago_em: Date.current)
    assert_not sem_vencimento.valid?
    assert_match "dia do vencimento", sem_vencimento.errors.full_messages.join
  end

  test "a billed company needs a due day" do
    outra = companies(:one)
    outra.mensalidade_valor = 100
    assert_not outra.valid?
    assert outra.errors[:dia_vencimento].any?
  end
end
