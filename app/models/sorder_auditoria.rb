# One entry in an order's history (SordersController#historico): who did
# what to the order, a passenger, someone on a pax list or a payment.
# alteracoes is {campo => [antes, depois]}, with campo an attribute of
# registro_type; a creation has only "depois", a deletion only "antes".
class SorderAuditoria < ApplicationRecord
  self.table_name = "sorder_auditorias"
  include DaEmpresa
  belongs_to :registro, polymorphic: true, optional: true

  # Records one action, by the signed-in account (Current.usuario). Called
  # by Auditavel, and by the code that moves an item's paid amounts with
  # update_columns (payments, commission payments, booked tours' down
  # payments), which skips callbacks. A down payment still without an order
  # (sorder_id nil) isn't recorded.
  def self.registrar!(registro, acao, alteracoes, sorder_id:, descricao: nil, company_id: registro.company_id)
    return if sorder_id.nil?

    # Decimals would be kept as JSON strings.
    alteracoes = alteracoes.transform_values { |valores| valores.map { |valor| valor.is_a?(BigDecimal) ? valor.to_f : valor } }
    create!(sorder_id: sorder_id, company_id: company_id, registro_type: registro.class.name, registro_id: registro.id,
            descricao: descricao, acao: acao, usuario: Current.usuario, alteracoes: alteracoes)
  end
end
