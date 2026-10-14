# Data that belongs to one Company: a signed-in request only sees and creates
# rows of Current.empresa_id (a user's company, or the one an admin picked).
# A user without a company sees none.
#
# New rows take the company of the record named by `da_empresa via:` (an
# order's passenger takes the order's), else Current.empresa_id. A reference
# to another company's record (a forged id) is refused, because the scope
# hides it.
module DaEmpresa
  extend ActiveSupport::Concern

  included do
    belongs_to :company
    default_scope { where(company_id: Current.empresa_id) if Current.filtrar_empresa }
    before_validation :definir_empresa, on: :create
    validate :referencias_da_empresa
  end

  class_methods do
    def da_empresa(via:)
      @empresa_via = via
    end

    def empresa_via
      @empresa_via
    end
  end

  private

  def definir_empresa
    self.company_id ||= (self.class.empresa_via && public_send(self.class.empresa_via)&.company_id) || Current.empresa_id
  end

  def referencias_da_empresa
    self.class.reflect_on_all_associations(:belongs_to).each do |associacao|
      # Required ones already fail with "must exist".
      next if associacao.polymorphic? || !associacao.options[:optional] || !(associacao.klass < DaEmpresa)
      next if self[associacao.foreign_key].blank? || public_send(associacao.name).present?

      errors.add(associacao.name, :invalid)
    end
  end
end
