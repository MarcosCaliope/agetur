# A passenger's commission (or an order's cost) can be paid in more than
# one bill: e.g. paid in a batch, then raised. Sorder#encerrar! keeps one
# open bill per origem by itself.
class AllowSeveralPayablesPerOrigem < ActiveRecord::Migration[7.2]
  def change
    remove_index :payables, %i[sorder_id sorder_item_id origem], unique: true, nulls_not_distinct: true,
                                                                 where: "origem IS NOT NULL", name: "index_payables_on_origem_da_ordem"
    add_index :payables, %i[sorder_item_id origem]
  end
end
