class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Not :registerable: users are created by an admin (/admins_backoffice/usuarios).
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  before_validation :limpar_permissoes

  # The routes (Permissao keys) the user may open, or all of them with
  # acesso_total, including screens added later. Without either, only the
  # home page.
  def pode?(controller, action)
    acesso_total? || permissoes.include?(Permissao.chave(controller, action))
  end

  private

  # Drops the form's blank placeholder and keys of routes that no longer exist.
  def limpar_permissoes
    self.permissoes = (permissoes.to_a.compact_blank & Permissao.chaves)
  end
end
