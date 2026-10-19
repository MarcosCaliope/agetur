# Relação de ordens (SISTGER's "Relação de O. Serviço" and its versions by
# vendor, roteiro, guide and hotel): the passengers of the orders in a
# period, filtered by roteiro, vendor, guide, driver, vehicle or hotel and
# shown one line per order (sintético) or per passenger (analítico),
# optionally grouped with subtotals. Grouping by vendor or hotel splits an
# order among its passengers' vendors/hotels.
#
# Cancelled passengers are left out unless asked for, and never count in
# the totals.
class RelacaoOrdens
  MODOS = { "sintetico" => "Sintético (uma linha por OS)", "analitico" => "Analítico (um passageiro por linha)" }.freeze
  AGRUPAMENTOS = {
    "" => "Sem agrupamento", "data" => "Data", "roteiro" => "Roteiro", "vendedor" => "Vendedor",
    "guia" => "Guia", "motorista" => "Motorista", "hotel" => "Hotel"
  }.freeze
  SITUACOES = { "" => "Abertas e encerradas", "abertas" => "Abertas", "encerradas" => "Encerradas" }.freeze
  # Filter param => [column, model, name column, label].
  FILTROS = {
    destination_id: ["sorders.destination_id", Destination, :description, "Roteiro"],
    vendor_id: ["sorder_items.vendor_id", Vendor, :sname, "Vendedor"],
    tourguide_id: ["sorders.tourguide_id", Tourguide, :sname, "Guia"],
    driver_id: ["sorders.driver_id", Driver, :sname, "Motorista"],
    vehicle_id: ["sorders.vehicle_id", Vehicle, :license, "Veículo"],
    hotel_id: ["sorder_items.hotel_id", Hotel, :sname, "Hotel"]
  }.freeze

  Linha = Struct.new(:sorder, :itens)

  attr_reader :inicio, :fim, :modo, :agrupar, :situacao

  def initialize(params)
    @params = params
    hoje = Time.zone.today
    @inicio = data_param(:inicio) || hoje.beginning_of_month
    @fim = data_param(:fim) || hoje
    @modo = MODOS.key?(params[:modo]) ? params[:modo] : "sintetico"
    @agrupar = AGRUPAMENTOS.key?(params[:agrupar].to_s) ? params[:agrupar].to_s : ""
    @situacao = SITUACOES.key?(params[:situacao].to_s) ? params[:situacao].to_s : ""
  end

  def analitico? = modo == "analitico"

  def cancelados? = @params[:cancelados] == "1"

  def filtro(nome) = @params[nome].presence

  def itens
    @itens ||= begin
      escopo = SorderItem.joins(:sorder)
        .includes(:hotel, :vendor, sorder: %i[destination tourguide driver vehicle])
        .where(sorders: { data: inicio.beginning_of_day..fim.end_of_day })
      escopo = escopo.ativos unless cancelados?
      escopo = escopo.where(sorders: { encerrada: situacao == "encerradas" }) if situacao.present?
      FILTROS.each { |nome, (coluna, *)| escopo = escopo.where(coluna => filtro(nome)) if filtro(nome) }
      escopo.order("sorders.data", :sorder_id, :sistger_sequencial, :id).to_a
    end
  end

  # [[group title, items]], in the group's order; one untitled group when not grouping.
  def grupos
    return [[nil, itens]] if agrupar.blank?

    itens.group_by { |item| chave(item) }.sort_by { |(ordem, _), _| ordem }.map { |(_, titulo), grupo| [titulo, grupo] }
  end

  # One line per order of `itens`, in their order.
  def linhas(itens)
    itens.group_by(&:sorder).map { |sorder, do_pedido| Linha.new(sorder, do_pedido) }
  end

  def self.totais(itens)
    contados = itens.reject(&:cancelado?)
    {
      pax: contados.sum { |item| item.qtdepax.to_i }, chd: contados.sum { |item| item.qtdechd.to_i },
      valor: contados.sum { |item| item.amount.to_f }, recebido: contados.sum { |item| item.amountpay.to_f },
      a_receber: contados.sum(&:total_passeio), comissao: contados.sum { |item| item.amountcomission.to_f }
    }
  end

  def totais = self.class.totais(itens)

  def ordens = itens.map(&:sorder_id).uniq.size

  # "Roteiro: X; Vendedor: Y" for the filters given.
  def descricao_filtros
    partes = FILTROS.filter_map do |nome, (_, modelo, coluna, rotulo)|
      "#{rotulo}: #{modelo.find_by(id: filtro(nome))&.public_send(coluna)}" if filtro(nome)
    end
    partes << "Situação: #{SITUACOES[situacao]}" if situacao.present?
    partes << "Inclui cancelados" if cancelados?
    partes.join("; ")
  end

  def titulo
    "Relação de ordens de serviço de #{I18n.l(inicio)} a #{I18n.l(fim)}"
  end

  # Query params that reproduce this report (the PDF link).
  def params_url
    { inicio: inicio, fim: fim, modo: modo, agrupar: agrupar.presence, situacao: situacao.presence,
      cancelados: ("1" if cancelados?) }.merge(FILTROS.keys.to_h { |nome| [nome, filtro(nome)] }).compact
  end

  private

  # [sort key, title] of the item's group.
  def chave(item)
    sorder = item.sorder
    case agrupar
    when "data" then [sorder.data.to_date, I18n.l(sorder.data.to_date)]
    when "roteiro" then nome(sorder.destination&.description, "Sem roteiro")
    when "vendedor" then nome(item.vendor&.sname, "Sem vendedor")
    when "guia" then nome(sorder.tourguide&.sname, "Sem guia")
    when "motorista" then nome(sorder.driver&.sname, "Sem motorista")
    when "hotel" then nome(item.hotel&.sname, "Sem hotel")
    end
  end

  # Named groups sort by name; the "Sem ..." group goes last.
  def nome(valor, vazio)
    valor.present? ? [[0, I18n.transliterate(valor).downcase], valor] : [[1, ""], vazio]
  end

  def data_param(nome)
    Date.iso8601(@params[nome].to_s) if @params[nome].present?
  rescue Date::Error
    nil
  end
end
