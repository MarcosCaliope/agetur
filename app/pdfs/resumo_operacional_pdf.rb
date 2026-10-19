# Resumo operacional (ResumoOperacional) laid out like SISTGER's printout:
# a three-line block per order (number and guide, date, destination and
# vehicle; the costs; value, commissions, costs and total) and the totals
# at the end. Each page repeats the title.
class ResumoOperacionalPdf < Prawn::Document
  include PdfFormatacao

  TAMANHO = 8
  LINHA = 11
  BLOCO = (LINHA * 3) + 6

  def initialize(resumo, empresa)
    super(page_size: "A4", page_layout: :landscape, margin: 28)
    @resumo = resumo

    cabecalho_empresa(empresa)
    titulo
    if resumo.linhas.empty?
      text "Nenhuma ordem no período.", size: 10
    else
      resumo.linhas.each { |linha| bloco(linha) }
      totais
    end
    number_pages "<page>/<total>", at: [bounds.right - 50, 0], width: 50, align: :right, size: 8
  end

  private

  def titulo
    text limpo(@resumo.titulo), size: 11, style: :bold, align: :center
    move_down 6
    stroke_horizontal_rule
    move_down 3
  end

  def nova_pagina_se_preciso(altura)
    return if cursor > altura + 12

    start_new_page
    titulo
  end

  def bloco(linha)
    nova_pagina_se_preciso(BLOCO)
    sorder = linha.sorder
    topo = cursor

    rotulo "O.S:", 0, topo
    valor number_with_delimiter(sorder.id, delimiter: "."), 22, topo, 60, style: :bold
    valor sorder.tourguide&.sname, 0, topo - LINHA, 105
    rotulo "Data", 110, topo
    valor data(sorder.data), 135, topo, 55
    rotulo "Destino", 195, topo
    valor sorder.destination&.description, 235, topo, 140
    rotulo "Veículo", 380, topo
    valor sorder.vehicle&.license, 418, topo, 90

    custos = [["Guia:", 110, 140], ["Valor Motorista:", 205, 275], ["Pedágio:", 340, 380],
              ["Combustível:", 445, 505], ["O. Despesas:", 570, 630]]
    Sorder::CUSTOS.zip(custos).each do |(coluna, *), (nome, x_rotulo, x_valor)|
      rotulo nome, x_rotulo, topo - LINHA
      numero linha.custo(coluna), x_valor, topo - LINHA, 55
    end

    y = topo - (LINHA * 2)
    rotulo "Valor OS", 110, y
    numero linha.valor, 150, y, 65, style: :bold
    rotulo "Valor Comissões", 230, y
    numero linha.comissoes, 300, y, 65, style: :bold
    rotulo "Valor Despesas", 520, y
    numero linha.despesas, 585, y, 55
    rotulo "Total O.S.", 660, y
    numero linha.total, 705, y, bounds.width - 705, style: :bold

    move_down BLOCO - 3
    stroke_horizontal_rule
    move_down 3
  end

  def totais
    nova_pagina_se_preciso(LINHA * 2)
    move_down 2
    totais = @resumo.totais
    y = cursor
    [["Valor Total O.S.:", totais[:valor]], ["Valor Total Comissões:", totais[:comissoes]],
     ["Valor Total Despesas:", totais[:despesas]], ["Total Geral O.S.:", totais[:total]]].each_with_index do |(nome, total), i|
      x = i * (bounds.width / 4)
      rotulo nome, x, y
      numero total, x + 95, y, (bounds.width / 4) - 105, style: :bold
    end
    move_down LINHA + 2
    stroke_horizontal_rule
  end

  def rotulo(texto, x, y)
    text_box limpo(texto), at: [x, y], width: 120, height: LINHA, size: TAMANHO, style: :bold, overflow: :truncate
  end

  def valor(texto, x, y, largura, style: :normal)
    text_box limpo(texto), at: [x, y], width: largura, height: LINHA, size: TAMANHO, style: style, overflow: :truncate
  end

  def numero(numero, x, y, largura, style: :normal)
    texto = number_with_precision(numero, precision: 2, delimiter: ".", separator: ",")
    text_box texto, at: [x, y], width: largura, height: LINHA, size: TAMANHO, style: style, align: :right, overflow: :truncate
  end

  # The built-in PDF fonts only cover Windows-1252; anything else becomes "?".
  def limpo(texto)
    texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
