# A company's monthly fee paid for one month (referencia, kept as the 1st).
# Admin-level billing, not the company's own data: no DaEmpresa scope, only
# admins see it (AdminsBackoffice::MensalidadesController).
#
# Paying a month moves the company's acesso_liberado_ate to that month's
# paid-through day (Company#acesso_pago_ate), never backwards, so a longer
# trial date set by hand survives. Deleting a payment recomputes it from the
# latest month still paid; with none left, the date stays as it is.
class Mensalidade < ApplicationRecord
  FORMAS = %w[PIX Boleto Transferência Dinheiro Cartão].freeze

  belongs_to :company

  before_validation :primeiro_dia_do_mes
  validates :referencia, :pago_em, presence: true
  validates :valor, numericality: { greater_than: 0 }
  validates :referencia, uniqueness: { scope: :company_id, message: "já tem pagamento registrado" }
  validate :empresa_com_vencimento

  after_create :liberar_acesso
  after_destroy :recalcular_acesso

  scope :recentes, -> { order(referencia: :desc) }

  def liberado_ate = company.acesso_pago_ate(referencia)

  private

  def primeiro_dia_do_mes
    self.referencia = referencia&.beginning_of_month
  end

  def empresa_com_vencimento
    errors.add(:base, "Informe o dia do vencimento da empresa antes de registrar pagamentos.") if company && company.dia_vencimento.blank?
  end

  def liberar_acesso
    company.update!(acesso_liberado_ate: [company.acesso_liberado_ate, liberado_ate].compact.max)
  end

  def recalcular_acesso
    ultima = company.mensalidades.maximum(:referencia)
    company.update!(acesso_liberado_ate: company.acesso_pago_ate(ultima)) if ultima
  end
end
