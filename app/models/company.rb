class Company < ApplicationRecord
  include Pesquisavel
  pesquisavel_por :name, :short_name, :cnpj, :city, :email

  LOGO_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  LOGO_MAX_SIZE = 2.megabytes

  belongs_to :state
  has_many :users, dependent: :nullify
  has_many :mensalidades, dependent: :restrict_with_error

  validates :dia_vencimento, numericality: { only_integer: true, in: 1..31 }, allow_nil: true
  validates :dias_tolerancia, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :mensalidade_valor, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :dia_vencimento, presence: { message: "é obrigatório para cobrar mensalidade" }, if: :cobrada?

  # A user sees only their own company (an admin sees them all).
  default_scope { where(id: Current.empresa_id) if Current.so_a_propria_empresa }

  # Uploaded logos. The legacy string columns logoentrada/logoform (a file
  # name under public/) are kept only as a fallback for older records.
  has_one_attached :logo_entrada
  has_one_attached :logo_formulario

  # Form checkboxes to drop an uploaded logo.
  attribute :remover_logo_entrada, :boolean, default: false
  attribute :remover_logo_formulario, :boolean, default: false

  validate :logos_are_images

  after_save :remover_logos_marcados

  # SISTGER's yes/no settings for service orders (tblFilial). The integer
  # ones hold 1/0; osincludechdcalc holds "S"/"N".
  OPCOES_OS = %i[osdupla osshowcan osshowcanrel osshowrep].freeze

  def os_dupla? = osdupla == 1
  def exibir_cancelados_na_os? = osshowcan == 1
  def exibir_cancelados_no_relatorio? = osshowcanrel == 1
  def exibir_repasse_na_os? = osshowrep == 1
  def incluir_chd_no_calculo? = osincludechdcalc == "S"

  # Access control (monthly fee), set only by admins at
  # /admins_backoffice/empresas: the company's own users (company_id, vendor
  # logins included) can't sign in, and are signed out, while it's blocked
  # by hand or past acesso_liberado_ate (the last day it's paid through;
  # blank means no limit). See User#active_for_authentication?.
  def acesso_suspenso?(hoje = Date.current)
    acesso_bloqueado? || acesso_vencido?(hoje)
  end

  def acesso_vencido?(hoje = Date.current)
    acesso_liberado_ate.present? && acesso_liberado_ate < hoje
  end

  # Monthly fee (Mensalidade): a company with mensalidade_valor is billed,
  # due on dia_vencimento each month (the month's last day when shorter).
  def cobrada? = mensalidade_valor.to_d.positive?

  def vencimento_em(mes)
    inicio = mes.beginning_of_month
    inicio.change(day: [dia_vencimento, inicio.end_of_month.day].min)
  end

  # Paying month M keeps access until the next month's due day plus the grace days.
  def acesso_pago_ate(referencia)
    vencimento_em(referencia.next_month) + dias_tolerancia.to_i
  end

  # The month the next payment pays: the one after the latest paid, else the current one.
  def proxima_referencia
    mensalidades.maximum(:referencia)&.next_month || Date.current.beginning_of_month
  end

  # The image to show for a logo (:entrada or :formulario): the upload, or a
  # legacy file name that actually exists under public/. nil when neither.
  def logo(tipo)
    anexo = tipo == :entrada ? logo_entrada : logo_formulario
    # An upload rejected by validation is attached in memory but never stored.
    return anexo if anexo.attached? && anexo.blob.persisted?

    legado = tipo == :entrada ? logoentrada : logoform
    legado if legado.present? && legacy_logo_file?(legado)
  end

  private

  def legacy_logo_file?(nome)
    public_dir = Rails.public_path.realpath
    caminho = public_dir.join(nome.to_s.delete_prefix("/")).expand_path
    caminho.to_s.start_with?("#{public_dir}/") && caminho.file?
  end

  def logos_are_images
    %i[logo_entrada logo_formulario].each do |campo|
      anexo = public_send(campo)
      next unless anexo.attached?

      if LOGO_TYPES.exclude?(anexo.blob.content_type)
        errors.add(campo, "deve ser uma imagem PNG, JPG, GIF ou WebP")
      elsif anexo.blob.byte_size > LOGO_MAX_SIZE
        errors.add(campo, "deve ter no máximo 2 MB")
      end
    end
  end

  # Skip the removal when a new file was uploaded in the same save.
  def remover_logos_marcados
    logo_entrada.purge_later if remover_logo_entrada && !attachment_changes.key?("logo_entrada")
    logo_formulario.purge_later if remover_logo_formulario && !attachment_changes.key?("logo_formulario")
  end
end
