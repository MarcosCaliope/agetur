# How the passenger pays (SISTGER's tblOrdemServicoItens.sFormaPagto),
# printed by order model 3.
class AddFormaPagamentoToSorderItems < ActiveRecord::Migration[7.2]
  def change
    add_column :sorder_items, :forma_pagamento, :string, limit: 1
  end
end
