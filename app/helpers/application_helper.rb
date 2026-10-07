module ApplicationHelper
  # "Último registro: nº 42 — MARIA (código SISTGER 1.234)" for a cadastro
  # list: the record with the highest number (id).
  def ultimo_registro(modelo)
    registro = modelo.order(:id).last
    texto =
      if registro
        partes = ["nº #{number_with_delimiter(registro.id)}", descricao_registro(registro).presence].compact.join(" — ")
        codigo = registro.try(:sistger_id)
        codigo ? "#{partes} (código SISTGER #{number_with_delimiter(codigo)})" : partes
      else
        "nenhum"
      end
    tag.p("Último registro: #{texto}", class: "text-muted small ultimo-registro")
  end

  # Text that identifies a record in "Último registro" lines.
  def descricao_registro(registro)
    case registro
    when Sorder then [registro.data&.strftime("%d/%m/%Y"), registro.destination&.description].compact.join(" — ")
    when Customer then registro.nome
    when Company then registro.name
    when Destination then registro.description
    when Vehicle then registro.license
    else registro.try(:sname)
    end
  end
end
