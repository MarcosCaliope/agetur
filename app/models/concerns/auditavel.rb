# Keeps an order's history (SorderAuditoria) of a model's records: the
# fields changed by each create and update, and the whole record when it's
# deleted. update_columns/update_all/upsert_all skip it, so code that moves
# paid amounts that way records itself; the SISTGER import isn't recorded.
#
# A model may define auditoria_sorder_id, auditoria_descricao (how the
# history names the record) and auditoria_company_id.
module Auditavel
  extend ActiveSupport::Concern

  # Bookkeeping columns, and the parent the history is already filed under.
  IGNORADOS = %w[id created_at updated_at lock_version company_id sorder_id sorder_item_id].freeze

  included do
    after_create { auditar("criou", saved_changes) }
    after_update { auditar(acao_auditada, saved_changes) }
    # Before the dependent records go (an item's pax list is delete_all'd).
    before_destroy(prepend: true) { @auditoria_exclusao = atributos_auditados_na_exclusao }
    after_destroy { auditar("excluiu", @auditoria_exclusao) }
  end

  def auditoria_sorder_id = sorder_id
  def auditoria_descricao = nil
  def auditoria_company_id = company_id

  private

  def acao_auditada = "alterou"

  def atributos_auditados_na_exclusao
    attributes.transform_values { |valor| [valor, nil] }
  end

  def auditar(acao, mudancas)
    alteracoes = mudancas.except(*IGNORADOS).reject { |_, (antes, depois)| antes.blank? && depois.blank? }
    return if alteracoes.empty?

    SorderAuditoria.registrar!(self, acao, alteracoes, sorder_id: auditoria_sorder_id, descricao: auditoria_descricao,
                                                       company_id: auditoria_company_id)
  end
end
