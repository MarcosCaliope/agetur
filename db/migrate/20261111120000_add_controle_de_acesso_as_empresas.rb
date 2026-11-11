# Suspensão do acesso dos usuários de uma empresa (mensalidade): bloqueio
# manual ou "liberado até" uma data. Só os admins mudam esses campos.
class AddControleDeAcessoAsEmpresas < ActiveRecord::Migration[7.2]
  def change
    change_table :companies, bulk: true do |t|
      t.boolean :acesso_bloqueado, null: false, default: false
      t.date :acesso_liberado_ate
    end
  end
end
