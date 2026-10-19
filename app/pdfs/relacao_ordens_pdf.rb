# Relação de ordens (RelacaoOrdens) in A4 landscape: one table, with a row
# per group title and subtotal, and the grand total at the end.
class RelacaoOrdensPdf < Prawn::Document
  include PdfFormatacao

  VALORES = ["PAX", "CHD", "Valor", "Recebido", "A receber", "Comissão"].freeze

  def initialize(relacao, empresa)
    super(page_size: "A4", page_layout: :landscape, margin: 28)
    @relacao = relacao

    cabecalho_empresa(empresa)
    text limpo(relacao.titulo), size: 13, style: :bold
    text limpo(relacao.descricao_filtros), size: 9 if relacao.descricao_filtros.present?
    move_down 8
    tabela
    numerar_paginas
  end

  private

  def colunas
    @relacao.analitico? ? %w[OS Data Roteiro Passageiro Hotel Vendedor] : ["OS", "Data", "Roteiro", "Guia", "Motorista", "Veículo"]
  end

  def tabela
    linhas = [colunas + VALORES]
    destaques, subtotais = [], []
    @relacao.grupos.each do |titulo, itens|
      if titulo
        destaques << linhas.size
        linhas << [{ content: limpo("#{RelacaoOrdens::AGRUPAMENTOS[@relacao.agrupar]}: #{titulo}"), colspan: 12 }]
      end
      linhas.concat(@relacao.analitico? ? itens.map { |item| passageiro(item) } : @relacao.linhas(itens).map { |linha| ordem(linha) })
      if titulo
        subtotais << linhas.size
        linhas << total("Subtotal #{titulo}", RelacaoOrdens.totais(itens))
      end
    end
    if @relacao.itens.empty?
      linhas << [{ content: "Nenhuma ordem com estes filtros.", colspan: 12 }]
    else
      subtotais << linhas.size
      linhas << total("Total: #{@relacao.ordens} #{@relacao.ordens == 1 ? 'ordem' : 'ordens'}", @relacao.totais)
    end

    table linhas, width: bounds.width, header: true, cell_style: { size: 8, padding: [2, 4] } do |t|
      t.row(0).font_style = :bold
      t.row(0).background_color = "DDDDDD"
      t.columns(6..11).align = :right
      destaques.each { |linha| t.row(linha).background_color = "EEEEEE" }
      destaques.each { |linha| t.row(linha).font_style = :bold }
      subtotais.each { |linha| t.row(linha).font_style = :bold }
    end
  end

  def ordem(linha)
    sorder = linha.sorder
    [sorder.id.to_s, data(sorder.data), sorder.destination&.description, sorder.tourguide&.sname, sorder.driver&.sname,
     sorder.vehicle&.license].map { |texto| limpo(texto) } + valores(RelacaoOrdens.totais(linha.itens))
  end

  def passageiro(item)
    nome = item.cancelado? ? "#{item.nome_passageiro} (cancelado)" : item.nome_passageiro
    [item.sorder_id.to_s, data(item.sorder.data), item.sorder.destination&.description, nome, item.hotel&.sname,
     item.vendor&.sname].map { |texto| limpo(texto) } + valores(RelacaoOrdens.totais([item]))
  end

  def total(rotulo, totais)
    [{ content: limpo(rotulo), colspan: 6, align: :right }] + valores(totais)
  end

  def valores(totais)
    [totais[:pax].to_s, totais[:chd].to_s] + totais.values_at(:valor, :recebido, :a_receber, :comissao).map { |valor| moeda(valor) }
  end

  def numerar_paginas
    number_pages "<page>/<total>", at: [bounds.right - 50, 0], width: 50, align: :right, size: 8
  end

  # The built-in PDF fonts only cover Windows-1252; anything else becomes "?".
  def limpo(texto)
    texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
