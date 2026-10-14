# Each User's routes (controller#action keys, see Permissao), or all of them
# with acesso_total. Admins are not bound by them. Existing users get
# acesso_total so nothing they could do before is blocked by the upgrade.
class AddPermissoesToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :name, :string
    add_column :users, :acesso_total, :boolean, null: false, default: false
    add_column :users, :permissoes, :string, array: true, null: false, default: []
    execute "UPDATE users SET acesso_total = TRUE"
  end

  def down
    remove_column :users, :permissoes
    remove_column :users, :acesso_total
    remove_column :users, :name
  end
end
