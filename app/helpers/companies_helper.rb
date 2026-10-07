module CompaniesHelper
  # logoform/logoentrada are optional plain filenames under public/, so skip
  # the tag when blank instead of letting image_tag raise on a nil source.
  def company_logo_tag(filename, size)
    image_tag(filename, width: size, height: size, skip_pipeline: true) if filename.present?
  end
end
