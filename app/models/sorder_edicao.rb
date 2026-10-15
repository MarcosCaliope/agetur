# Someone with an order's edit form open, kept alive by the form while it
# stays open (edicao_ordem.js). Only warns the others: the save itself is
# guarded by Sorder's lock_version.
class SorderEdicao < ApplicationRecord
  self.table_name = "sorder_edicoes"

  # The form reports every 30 s; a row older than this is a closed form.
  VALIDADE = 2.minutes

  belongs_to :sorder

  scope :ativas, -> { where(visto_em: VALIDADE.ago..) }
end
