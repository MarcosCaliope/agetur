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

  # Bootstrap Icons (eye, pencil, trash), inlined because the asset pipeline
  # has no icon font.
  ICONES_ACAO = {
    exibir: ["Exibir", nil, [
      "M16 8s-3-5.5-8-5.5S0 8 0 8s3 5.5 8 5.5S16 8 16 8M1.173 8a13 13 0 0 1 1.66-2.043C4.12 4.668 5.88 3.5 8 3.5s3.879 1.168 5.168 2.457A13 13 0 0 1 14.828 8q-.086.13-.195.288c-.335.48-.83 1.12-1.465 1.755C11.879 11.332 10.119 12.5 8 12.5s-3.879-1.168-5.168-2.457A13 13 0 0 1 1.172 8z",
      "M8 5.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5M4.5 8a3.5 3.5 0 1 1 7 0 3.5 3.5 0 0 1-7 0"
    ]],
    editar: ["Editar", nil, [
      "M12.146.146a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-10 10a.5.5 0 0 1-.168.11l-5 2a.5.5 0 0 1-.65-.65l2-5a.5.5 0 0 1 .11-.168zM11.207 2.5 13.5 4.793 14.793 3.5 12.5 1.207zm1.586 3L10.5 3.207 4 9.707V10h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.293zm-9.761 5.175-.106.106-1.528 3.821 3.821-1.528.106-.106A.5.5 0 0 1 5 12.5V12h-.5a.5.5 0 0 1-.5-.5V11h-.5a.5.5 0 0 1-.468-.325"
    ]],
    excluir: ["Excluir", "text-danger", [
      "M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5m2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5m3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0z",
      "M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4zM2.5 3h11V2h-11z"
    ]]
  }.freeze

  # Exibir/Editar/Excluir link in a list row, shown as an icon. The label
  # stays as the tooltip and as hidden text for screen readers. Goes through
  # link_to, so the route permissions still apply.
  def icone_link(acao, url, html_options = {})
    rotulo, cor, caminhos = ICONES_ACAO.fetch(acao)
    svg = tag.svg(safe_join(caminhos.map { |d| tag.path(d: d) }),
                  xmlns: "http://www.w3.org/2000/svg", width: 16, height: 16, fill: "currentColor",
                  viewBox: "0 0 16 16", "aria-hidden": true, focusable: false)
    classes = ["icone-acao", cor, html_options[:class]].compact.join(" ")
    link_to(url, html_options.merge(class: classes, title: rotulo)) do
      svg + tag.span(rotulo, class: "sr-only")
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
