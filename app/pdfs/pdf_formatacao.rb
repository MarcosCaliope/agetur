# Shared bits of the cash book PDFs: money/date formatting and the company
# header.
module PdfFormatacao
  include ActionView::Helpers::NumberHelper

  def moeda(valor)
    number_to_currency(valor.to_d)
  end

  def data(valor, format: :default)
    I18n.l(valor.to_date, format: format)
  end

  def cabecalho_empresa(empresa)
    return unless empresa

    text empresa.name.to_s, size: 14, style: :bold
    text [empresa.address, empresa.city, empresa.phone].compact_blank.join(" - "), size: 9
    text [("CNPJ: #{empresa.cnpj}" if empresa.cnpj.present?), empresa.email, empresa.site].compact_blank.join(" - "), size: 9
    move_down 12
  end
end
