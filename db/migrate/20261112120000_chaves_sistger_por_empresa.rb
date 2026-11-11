# Várias bases SISTGER no mesmo banco, uma por empresa.
#
# Cada base numera seus registros a partir de 1, então a chave legada passa a
# ser única por empresa, não no banco inteiro. A empresa em si deixa de ser
# casada pelo código do SISTGER (toda base tem a filial 1): a etapa "empresa"
# grava na empresa de destino.
#
# O número da ordem deixa de ser o id: sorders.numero, único por empresa. As
# ordens existentes ficam com o número que já mostravam (o id).
class ChavesSistgerPorEmpresa < ActiveRecord::Migration[7.2]
  TABELAS = %i[agencies customers destinations drivers hotels sorders tourguides vehicles vendors].freeze

  def up
    TABELAS.each do |tabela|
      remove_index tabela, :sistger_id
      add_index tabela, %i[company_id sistger_id], unique: true
    end
    remove_index :companies, :sistger_id
    add_index :companies, :sistger_id

    remove_index :sorder_items, %i[sistger_numero sistger_sequencial]
    add_index :sorder_items, %i[company_id sistger_numero sistger_sequencial], unique: true
    remove_index :cash_entries, %i[sistger_numero sistger_linha]
    add_index :cash_entries, %i[company_id sistger_numero sistger_linha], unique: true

    add_column :sorders, :numero, :integer
    execute "UPDATE sorders SET numero = id"
    change_column_null :sorders, :numero, false
    add_index :sorders, %i[company_id numero], unique: true
  end

  def down
    remove_index :sorders, %i[company_id numero]
    remove_column :sorders, :numero

    remove_index :cash_entries, %i[company_id sistger_numero sistger_linha]
    add_index :cash_entries, %i[sistger_numero sistger_linha], unique: true
    remove_index :sorder_items, %i[company_id sistger_numero sistger_sequencial]
    add_index :sorder_items, %i[sistger_numero sistger_sequencial], unique: true

    remove_index :companies, :sistger_id
    add_index :companies, :sistger_id, unique: true
    TABELAS.each do |tabela|
      remove_index tabela, %i[company_id sistger_id]
      add_index tabela, :sistger_id, unique: true
    end
  end
end
