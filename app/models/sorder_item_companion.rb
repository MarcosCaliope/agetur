# Someone travelling under a passenger item (SISTGER's "lista pax",
# tblListaPax): the item's holder is SorderItem#nome_passageiro.
class SorderItemCompanion < ApplicationRecord
  include Auditavel
  belongs_to :sorder_item
  belongs_to :customer, optional: true

  validates :snome, presence: true

  def auditoria_sorder_id = sorder_item&.sorder_id
  def auditoria_company_id = sorder_item&.company_id
  def auditoria_descricao = [sorder_item&.nome_passageiro, snome].compact.join(" — ")

  def descricao
    extras = [[documenttype, document].compact_blank.join(" ").presence, ("CHD" if chd?), ("colo" if colo?)].compact
    extras.any? ? "#{snome} (#{extras.join(', ')})" : snome
  end
end
