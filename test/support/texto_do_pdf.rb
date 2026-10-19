# The text of a Prawn PDF, one line per text run. Prawn writes each run as
# hex strings split by kerning ([<4d79> -15 <537472>] TJ), in Windows-1252.
module TextoDoPdf
  def texto_do_pdf(pdf)
    pdf.b.scan(/\[(.*?)\] TJ/).map do |(partes)|
      partes.scan(/<(\h*)>/).map { |(hex)| [hex].pack("H*") }.join.force_encoding("Windows-1252").encode("UTF-8")
    end.join("\n")
  end
end
