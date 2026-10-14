# Every cadastro and movement belongs to a company (DaEmpresa); states stay
# shared. Existing rows, and existing users, go to the main company: the one
# with most service orders, else the one imported from SISTGER, else the first.
class AddCompanyToRecords < ActiveRecord::Migration[7.2]
  TABELAS = %i[agencies customers hotels vendors tourguides drivers vehicles destinations pickup_times
               bookings booking_items sorder_items sorder_item_payments cash_entries payables].freeze

  def up
    TABELAS.each { |tabela| add_reference tabela, :company, foreign_key: true }
    add_reference :users, :company, foreign_key: true

    empresa = select_value(<<~SQL)
      SELECT id FROM companies
       ORDER BY (SELECT COUNT(*) FROM sorders WHERE sorders.company_id = companies.id) DESC,
                sistger_id IS NULL, sistger_id, id
       LIMIT 1
    SQL
    if empresa
      (TABELAS + %i[sorders users]).each { |tabela| execute "UPDATE #{tabela} SET company_id = #{Integer(empresa)} WHERE company_id IS NULL" }
    elsif (TABELAS + [:sorders]).any? { |tabela| select_value("SELECT 1 FROM #{tabela} LIMIT 1") }
      raise "Cadastre uma empresa antes: há registros sem empresa para vincular."
    end

    (TABELAS + [:sorders]).each { |tabela| change_column_null tabela, :company_id, false }
  end

  def down
    change_column_null :sorders, :company_id, true
    remove_reference :users, :company, foreign_key: true
    TABELAS.each { |tabela| remove_reference tabela, :company, foreign_key: true }
  end
end
