module ApplicationHelper
  # A link to a route the signed-in user may not open (Novo, Exibir, Editar,
  # Excluir, Encerrar...) is left out, so each screen only offers what the
  # admin checked in the user's cadastro. See Permissao.
  def link_to(*args, &block)
    url, html_options = block ? args.first(2) : args[1, 2]
    rota_permitida?(url, html_options) ? super : "".html_safe
  end

  def rota_permitida?(url, html_options = nil)
    return true if url.nil? || admin_signed_in? || !user_signed_in? # acesso_total still misses admin-only screens

    uri = URI.parse(url_for(url))
    return true if uri.host.present? && uri.host != request.host
    return true unless uri.path.to_s.start_with?("/")

    metodo = html_options.is_a?(Hash) ? (html_options[:method] || html_options.dig(:data, :method)) : nil
    metodo = (metodo || :get).to_s.downcase
    # Lists repeat the same routes with other ids: recognize each shape once.
    (@rotas_permitidas ||= {}).fetch([uri.path.gsub(/\d+/, "0"), metodo]) do |chave|
      rota = Rails.application.routes.recognize_path(uri.path, method: metodo)
      @rotas_permitidas[chave] = !Permissao.verificado?(rota[:controller]) || pode_acessar?(rota[:controller], rota[:action])
    end
  rescue ActionController::RoutingError, URI::InvalidURIError
    true
  end

  # Section of the manual (ajuda/index) about each screen, by
  # "controller#action" or controller. Other screens (cadastros) open the
  # manual's top.
  SECOES_DA_AJUDA = {
    "bookings" => "agendamentos", "booking_items" => "agendamentos", "booking_item_payments" => "agendamentos",
    "vendas" => "vendas", "conferencia_sinais" => "sinais",
    "sorders" => "ordens", "sorders#encerrar" => "encerramento", "sorders#reabrir" => "encerramento",
    "sorder_items#movimentar" => "transferir", "sorder_items#showcomis" => "comissoes",
    "sorder_item_payments" => "recebimentos", "commission_payments" => "comissoes", "payables" => "contas",
    "cash_entries" => "caixa", "relacao_ordens" => "relatorios", "resumo_operacional" => "relatorios",
    "agendamentos_por_usuario" => "relatorios", "passeios_repassados" => "relatorios",
    "pickup_times" => "configuracoes", "vendor_destinations" => "configuracoes", "vendors" => "configuracoes",
    "destinations" => "configuracoes", "companies" => "configuracoes",
    "admins_backoffice/users" => "acesso", "sistger_imports" => "acesso", "sistger_exclusoes" => "acesso", "senhas" => "acesso"
  }.freeze

  # The layouts' "Ajuda" link, opening the manual at this screen's section.
  def link_ajuda(**html_options)
    secao = SECOES_DA_AJUDA["#{controller_path}##{action_name}"] || SECOES_DA_AJUDA[controller_path]
    link_to ajuda_path(anchor: secao), title: "Ajuda sobre esta tela", **html_options do
      safe_join([tag.i(class: "fa fa-question-circle", "aria-hidden": true), " Ajuda"])
    end
  end

  # Icon-only link (Font Awesome 4, from the gentelella theme); the title is the tooltip and the accessible name.
  def link_icone(icone, titulo, url, html_options = {})
    link_to url, html_options.merge(title: titulo, "aria-label": titulo) do
      tag.i(class: "fa fa-lg fa-#{icone}", "aria-hidden": true)
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
