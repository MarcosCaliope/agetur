module ApplicationHelper
  # A link to a route the signed-in user may not open (Novo, Exibir, Editar,
  # Excluir, Encerrar...) is left out, so each screen only offers what the
  # admin checked in the user's cadastro. See Permissao.
  def link_to(*args, &block)
    url, html_options = block ? args.first(2) : args[1, 2]
    rota_permitida?(url, html_options) ? super : "".html_safe
  end

  def rota_permitida?(url, html_options = nil)
    return true if url.nil? || admin_signed_in? || !user_signed_in? || current_user.acesso_total?

    uri = URI.parse(url_for(url))
    return true if uri.host.present? && uri.host != request.host
    return true unless uri.path.to_s.start_with?("/")

    metodo = html_options.is_a?(Hash) ? (html_options[:method] || html_options.dig(:data, :method)) : nil
    metodo = (metodo || :get).to_s.downcase
    # Lists repeat the same routes with other ids: recognize each shape once.
    (@rotas_permitidas ||= {}).fetch([uri.path.gsub(/\d+/, "0"), metodo]) do |chave|
      rota = Rails.application.routes.recognize_path(uri.path, method: metodo)
      @rotas_permitidas[chave] = !Permissao.controlado?(rota[:controller]) || pode_acessar?(rota[:controller], rota[:action])
    end
  rescue ActionController::RoutingError, URI::InvalidURIError
    true
  end

  # Icon-only link (Font Awesome 4, from the gentelella theme); the title is the tooltip and the accessible name.
  def link_icone(icone, titulo, url, html_options = {})
    link_to url, html_options.merge(title: titulo, "aria-label": titulo) do
      tag.i(class: "fa fa-#{icone}", "aria-hidden": true)
    end
  end

  def sim_nao(valor)
    valor ? "Sim" : "Não"
  end

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
