# The single-order PDF (/sorders/:id/export), laid out like SISTGER's
# model 6 order (OSmod6): company and trip on top of every page, one block
# per passenger with document, phone, PAX/CHD, time, amount to receive and
# vendor, the pax list under the holder and the passenger's notes under the
# hotel, and KM / notes fields at the foot.
#
# As SISTGER, cancelled passengers and those passed to another agency only
# show when the company asks ("Exibir cancelados na OS" / "Exibir repasse
# na OS"), and the totals count neither.
class SorderExportPdf < Prawn::Document
  include PdfFormatacao

  COLUNAS = { hotel: 170, apto: 35, titular: 150, documento: 85, telefone: 92, pax: 28, chd: 28,
              hora: 36, valor: 60, solicitante: 118 }.freeze # 802 pt, the A4 landscape width inside the margins
  TITULOS = { hotel: "HOTEL/POUSADA", apto: "APTO", titular: "PASSAGEIRO TITULAR", documento: "DOCUMENTO",
              telefone: "TELEFONES", pax: "PAX", chd: "CHD", hora: "HORA", valor: "VALOR", solicitante: "SOLICITANTE" }.freeze
  A_DIREITA = %i[pax chd valor].freeze
  ALTURA_CABECALHO = 100
  ALTURA_RODAPE = 42
  LINHA_TITULAR = 13
  LINHA_ACOMPANHANTE = 9

  def initialize(sorder)
    super(page_size: "A4", page_layout: :landscape, margin: 20, info: { Title: "Ordem de Serviço #{sorder.id}" })
    @sorder = sorder
    @empresa = sorder.company
    @x = COLUNAS.keys.zip(COLUNAS.values.inject([0]) { |posicoes, largura| posicoes << posicoes.last + largura }).to_h

    repeat(:all) do
      cabecalho
      rodape
    end
    bounding_box([0, bounds.top - ALTURA_CABECALHO], width: bounds.width, height: bounds.height - ALTURA_CABECALHO - ALTURA_RODAPE) do
      itens.each { |item| passageiro(item) }
      totais
    end
    number_pages "Página <page> de <total>", at: [bounds.right - 120, 12], width: 120, align: :right, size: 8
  end

  private

  def itens
    @itens ||= begin
      itens = @sorder.sorder_items.includes(:hotel, :vendor, :agency, :companions)
                     .order(Arel.sql("sorder_items.sistger_sequencial IS NULL, sorder_items.sistger_sequencial, sorder_items.id"))
      itens = itens.ativos unless @empresa&.exibir_cancelados_na_os?
      itens = itens.where(agency_id: nil) unless @empresa&.exibir_repasse_na_os?
      itens.to_a
    end
  end

  def cabecalho
    bounding_box([0, bounds.top], width: bounds.width, height: ALTURA_CABECALHO) do
      logo
      empresa = @empresa
      if empresa
        linhas = [
          [["", empresa.name, true]],
          [["End: ", empresa.address]],
          [["", [empresa.city, empresa.state&.uf].compact_blank.join("  ")], ["   Cnpj: ", empresa.cnpj]],
          [["email: ", empresa.email]],
          [["Web: ", empresa.site]],
          [["Fones: ", empresa.phone]]
        ]
        linhas.each_with_index do |partes, i|
          formatted_text_box partes.reject { |rotulo, valor| rotulo.present? && valor.blank? }.flat_map { |rotulo, valor, destaque|
            [{ text: limpo(rotulo), styles: [:bold] }, { text: limpo(valor), styles: (destaque ? [:bold] : []) }]
          }, at: [112, bounds.top - 2 - i * 11], width: 340, height: 11, size: 8, overflow: :shrink_to_fit
        end
      end

      stroke_vertical_line bounds.top, bounds.top - 78, at: 462
      ordem = [
        [["ORDEM DE SERVIÇO   ", true], ["#{number_with_delimiter(@sorder.id, delimiter: '.')}      ", true], ["DATA:  ", true],
         [@sorder.data && data(@sorder.data)]],
        [["DESTINO:  ", true], [@sorder.destination&.description]],
        [["VEÍCULO PLACA:  ", true], ["#{@sorder.vehicle&.license}    "], ["MOTORISTA:  ", true], [@sorder.driver&.sname]],
        [["GUIA:  ", true], [@sorder.tourguide&.sname]]
      ]
      ordem.each_with_index do |partes, i|
        formatted_text_box partes.map { |texto, negrito| { text: limpo(texto), styles: (negrito ? [:bold] : []) } },
                           at: [475, bounds.top - 6 - i * 13 - (i.zero? ? 0 : 4)], width: bounds.width - 475, height: 13,
                           size: (i.zero? ? 10 : 9), overflow: :shrink_to_fit
      end

      stroke_horizontal_line 0, bounds.width, at: bounds.top - 80
      TITULOS.each do |coluna, titulo|
        celula(coluna, titulo, bounds.top - 84, size: 8, style: :bold)
      end
    end
  end

  def logo
    arquivo = @empresa&.logo(:formulario)
    @imagem_logo = if arquivo.is_a?(String)
                     Rails.public_path.join(arquivo.delete_prefix("/")).to_s
                   elsif arquivo && %w[image/png image/jpeg].include?(arquivo.content_type)
                     StringIO.new(arquivo.download)
                   end
    image @imagem_logo, at: [0, bounds.top], fit: [105, 76] if @imagem_logo
  rescue Prawn::Errors::UnsupportedImageType
    nil
  end

  def rodape
    bounding_box([0, ALTURA_RODAPE - 4], width: bounds.width, height: ALTURA_RODAPE - 4) do
      text_box "KM INICIAL", at: [10, 30], size: 8, style: :bold
      stroke_horizontal_line 72, 200, at: 21
      text_box "KM FINAL", at: [10, 14], size: 8, style: :bold
      stroke_horizontal_line 72, 200, at: 5
      text_box "Observ.:", at: [215, 30], size: 8, style: :bold
      text_box limpo(@sorder.sobservacoes), at: [255, 30], width: 400, height: 30, size: 7, overflow: :shrink_to_fit
    end
  end

  def passageiro(item)
    acompanhantes = item.companions.to_a
    observacao = limpo(item.comments).strip
    altura_obs = observacao.empty? ? 0 : height_of(observacao, width: COLUNAS[:hotel] - 4, size: 6) + 2
    altura = LINHA_TITULAR + [acompanhantes.size * LINHA_ACOMPANHANTE, altura_obs].max + 5
    bounds.move_past_bottom if cursor < altura
    topo = cursor

    stroke_horizontal_line 0, bounds.width, at: topo
    y = topo - 2
    celula(:hotel, item.hotel&.sname, y)
    celula(:apto, item.apto, y)
    celula(:titular, [item.nome_passageiro, situacao(item)].compact_blank.join(" "), y)
    celula(:documento, [item.documenttype, item.document].compact_blank.join(" "), y, size: 7)
    celula(:telefone, item.phone, y, size: 7)
    celula(:pax, item.qtdepax.to_i, y)
    celula(:chd, item.qtdechd.to_i, y)
    celula(:hora, item.hour, y)
    celula(:valor, valor(item.total_passeio), y)
    celula(:solicitante, item.vendor&.sname, y)

    y -= LINHA_TITULAR
    text_box observacao, at: [@x[:hotel] + 2, y], width: COLUNAS[:hotel] - 4, height: altura_obs, size: 6 unless observacao.empty?
    acompanhantes.each_with_index do |pessoa, i|
      linha = y - i * LINHA_ACOMPANHANTE
      celula(:titular, [pessoa.snome, ("(CHD)" if pessoa.chd?), ("(colo)" if pessoa.colo?)].compact.join(" "), linha, size: 7)
      celula(:documento, [pessoa.documenttype, pessoa.document].compact_blank.join(" "), linha, size: 7)
    end
    move_cursor_to topo - altura
  end

  def situacao(item)
    return "(CANCELADO)" if item.cancelado?

    "(repassado: #{item.agency&.sname})" if item.agency_id
  end

  # What the totals count: neither cancelled nor passed to another agency.
  def contados
    itens.reject { |item| item.cancelado? || item.agency_id }
  end

  def totais
    pax = contados.sum { |item| item.qtdepax.to_i }
    chd = contados.sum { |item| item.qtdechd.to_i }
    bounds.move_past_bottom if cursor < 20
    stroke_horizontal_line 0, bounds.width, at: cursor
    move_down 6
    text "Número de PAX: #{pax}      Chd: #{chd}      Total Pax: #{pax + chd}      " \
         "Valor Total a Receber: #{valor(contados.sum(&:total_passeio))}", size: 9, style: :bold, indent_paragraphs: 100
  end

  def celula(coluna, conteudo, y, size: 9, style: :normal)
    # Right-aligned numbers keep a gap before the next column.
    largura = COLUNAS[coluna] - (A_DIREITA.include?(coluna) ? 8 : 4)
    text_box limpo(conteudo), at: [@x[coluna] + 2, y], width: largura, height: size + 3, size: size, style: style,
                              align: A_DIREITA.include?(coluna) ? :right : :left, overflow: :shrink_to_fit, min_font_size: 5
  end

  def valor(numero)
    number_with_precision(numero.to_d, precision: 2, delimiter: ".", separator: ",")
  end

  # The built-in PDF fonts only cover Windows-1252; anything else becomes "?".
  def limpo(texto)
    texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
