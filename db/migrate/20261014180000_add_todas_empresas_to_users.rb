# A user with todas_empresas picks in the header which company's data to work
# in, as an admin does; otherwise they're bound to company_id.
class AddTodasEmpresasToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :todas_empresas, :boolean, null: false, default: false
  end
end
