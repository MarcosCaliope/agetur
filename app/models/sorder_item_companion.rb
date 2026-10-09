# Someone travelling under a passenger item (SISTGER's "lista pax",
# tblListaPax): the item's holder is SorderItem#nome_passageiro.
class SorderItemCompanion < ApplicationRecord
  belongs_to :sorder_item
  belongs_to :customer, optional: true

  validates :snome, presence: true

  def descricao
    extras = [[documenttype, document].compact_blank.join(" ").presence, ("CHD" if chd?), ("colo" if colo?)].compact
    extras.any? ? "#{snome} (#{extras.join(', ')})" : snome
  end
end
