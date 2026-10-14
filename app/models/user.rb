class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Not :registerable: users are created by an admin (/admins_backoffice/usuarios).
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  # The company whose data the user sees (DaEmpresa). With todas_empresas
  # they pick it in the header instead; with neither, they see no data.
  belongs_to :company, optional: true

  TODAS_EMPRESAS = "todas".freeze

  before_validation :limpar_permissoes

  # The routes (Permissao keys) the user may open, or all of them with
  # acesso_total, including screens added later. Without either, only the
  # home page.
  def pode?(controller, action)
    acesso_total? || permissoes.include?(Permissao.chave(controller, action))
  end

  # The form's single "Empresa" select: blank, TODAS_EMPRESAS or a company id.
  def acesso_empresa
    todas_empresas? ? TODAS_EMPRESAS : company_id
  end

  def acesso_empresa=(valor)
    self.todas_empresas = valor.to_s == TODAS_EMPRESAS
    self.company_id = todas_empresas? ? nil : valor.presence
  end

  private

  # Drops the form's blank placeholder and keys of routes that no longer exist.
  def limpar_permissoes
    self.permissoes = (permissoes.to_a.compact_blank & Permissao.chaves)
  end
end
