module CompaniesHelper
  # <img> for a company logo (:entrada or :formulario), or nil when the
  # company has none. Only the height is fixed so logos keep their aspect ratio.
  def company_logo_tag(company, tipo, height: 50, **options)
    logo = company&.logo(tipo)
    return if logo.blank?

    src = logo.is_a?(String) ? logo : rails_blob_path(logo, only_path: true)
    image_tag(src, { height: height, alt: "Logo #{company.name}", skip_pipeline: true }.merge(options))
  end
end
