class Company < ApplicationRecord
  LOGO_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  LOGO_MAX_SIZE = 2.megabytes

  belongs_to :state

  # Uploaded logos. The legacy string columns logoentrada/logoform (a file
  # name under public/) are kept only as a fallback for older records.
  has_one_attached :logo_entrada
  has_one_attached :logo_formulario

  # Form checkboxes to drop an uploaded logo.
  attribute :remover_logo_entrada, :boolean, default: false
  attribute :remover_logo_formulario, :boolean, default: false

  validate :logos_are_images

  after_save :remover_logos_marcados

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
