# The single-order PDF (/sorders/:id/export), in the SISTGER print model the
# company picks (Company#osmodel, SISTGER's iModeloOS; samples OSmod2..7).
# Every model has the company and trip on top of every page and one block
# per passenger; they differ in the columns, in how the pax list is shown
# and in the foot of the page:
#
#   2  one line per passenger with document and "repassado para", no pax list
#   3  like 2 with the pax list (with documents) and the payment form
#   4  like 2 with tall rows to write on
#   5  customer code instead of document, the pax list under a rule
#   6  document column and the pax list with documents (the default)
#   7  passenger first, pax list on one line, colo count, cash fields at the foot
#
# As SISTGER, cancelled passengers and those passed to another agency only
# show when the company asks ("Exibir cancelados na OS" / "Exibir repasse
# na OS"), and the totals count neither.
class SorderExportPdf < Prawn::Document
  include PdfFormatacao

  TITULOS = { hotel: "HOTEL/POUSADA", apto: "APTO", titular: "PASSAGEIRO TITULAR", documento: "DOCUMENTO",
              cod_cliente: "COD.CLIENTE", telefone: "TELEFONES", pax: "PAX", chd: "CHD", colo: "COLO", hora: "HORA",
              valor: "VALOR", solicitante: "SOLICITANTE", repassado: "REPASSADO PARA", cod: "COD",
              nome_pax: "NOME DO PAX / Acompanhantes", identidade: "IDENTIDADE" }.freeze
  A_DIREITA = %i[pax chd colo valor cod_cliente cod].freeze
  MENORES = %i[documento telefone identidade].freeze # printed smaller, as in SISTGER

  # Column widths add up to 802 pt, the A4 landscape width inside the margins.
  SIMPLES = { hotel: 160, apto: 32, titular: 150, documento: 80, telefone: 90, pax: 26, chd: 26, hora: 36, valor: 56,
              solicitante: 80, repassado: 66 }.freeze
  MODELOS = {
    2 => { colunas: SIMPLES },
    3 => { colunas: SIMPLES, acompanhantes: :lista, forma_pagamento: true },
    4 => { colunas: SIMPLES, altura_minima: 48 },
    5 => { colunas: { hotel: 160, apto: 32, titular: 150, cod_cliente: 80, telefone: 90, pax: 26, chd: 26, hora: 36, valor: 56,
                      solicitante: 80, repassado: 66 },
           acompanhantes: :lista, documento_acompanhante: :cod_cliente, regua_acompanhantes: true },
    6 => { colunas: { hotel: 170, apto: 35, titular: 150, documento: 85, telefone: 92, pax: 28, chd: 28, hora: 36, valor: 60,
                      solicitante: 118 },
           acompanhantes: :lista },
    7 => { colunas: { cod: 40, nome_pax: 200, hotel: 120, apto: 32, solicitante: 90, identidade: 80, pax: 26, chd: 26, colo: 26,
                      hora: 40, valor: 52, telefone: 70 },
           acompanhantes: :linha, observacao: :cod, rodape: :caixa }
  }.freeze
  PADRAO = 6
  NOMES = { 2 => "2 - Uma linha por passageiro, sem lista pax", 3 => "3 - Com lista pax e forma de pagamento",
            4 => "4 - Uma linha por passageiro, linhas altas", 5 => "5 - Código do cliente e lista pax",
            6 => "6 - Documento e lista pax", 7 => "7 - Passageiro primeiro, com campos de caixa" }.freeze

  ALTURA_CABECALHO = 100
  ALTURAS_RODAPE = { km: 42, caixa: 66 }.freeze
  LINHA_TITULAR = 13
  LINHA_ACOMPANHANTE = 9

  # The company's model, or the default when it has none SISTGER prints here.
  def self.modelo_da(empresa)
    MODELOS.key?(empresa&.osmodel) ? empresa.osmodel : PADRAO
  end

  attr_reader :modelo

  def initialize(sorder, modelo: nil)
    super(page_size: "A4", page_layout: :landscape, margin: 20, info: { Title: "Ordem de Serviço #{sorder.id}" })
    @sorder = sorder
    @empresa = sorder.company
    @modelo = MODELOS.key?(modelo) ? modelo : self.class.modelo_da(@empresa)
    @config = MODELOS.fetch(@modelo)
    @colunas = @config[:colunas]
    @x = @colunas.keys.zip(@colunas.values.inject([0]) { |posicoes, largura| posicoes << posicoes.last + largura }).to_h
    altura_rodape = ALTURAS_RODAPE.fetch(@config.fetch(:rodape, :km))

    repeat(:all) do
      cabecalho
      @config[:rodape] == :caixa ? rodape_caixa(altura_rodape) : rodape_km(altura_rodape)
    end
    bounding_box([0, bounds.top - ALTURA_CABECALHO], width: bounds.width, height: bounds.height - ALTURA_CABECALHO - altura_rodape) do
      itens.each { |item| passageiro(item) }
      totais
    end
    number_pages "Modelo #{@modelo}  ·  Página <page> de <total>", at: [bounds.right - 160, 2], width: 160, align: :right, size: 8
  end

  private

  def itens
    @itens ||= begin
      itens = @sorder.sorder_items.includes(:hotel, :vendor, :agency, :customer, :companions)
                     .order(Arel.sql("sorder_items.sistger_sequencial IS NULL, sorder_items.sistger_sequencial, sorder_items.id"))
      itens = itens.ativos unless @empresa&.exibir_cancelados_na_os?
      itens = itens.where(agency_id: nil) unless @empresa&.exibir_repasse_na_os?
      itens.to_a
    end
  end

  # What the totals count: neither cancelled nor passed to another agency.
  def contados
    itens.reject { |item| item.cancelado? || item.agency_id }
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
      @colunas.each_key do |coluna|
        celula(coluna, TITULOS.fetch(coluna), bounds.top - 84, size: 8, style: :bold)
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

  def rodape_km(altura)
    bounding_box([0, altura - 4], width: bounds.width, height: altura - 4) do
      text_box "KM INICIAL", at: [10, 30], size: 8, style: :bold
      stroke_horizontal_line 72, 200, at: 21
      text_box "KM FINAL", at: [10, 14], size: 8, style: :bold
      stroke_horizontal_line 72, 200, at: 5
      observacoes_da_ordem(215)
    end
  end

  # Model 7: blanks for the driver's cash account of the trip.
  def rodape_caixa(altura)
    bounding_box([0, altura - 4], width: bounds.width, height: altura - 4) do
      [["ORDEM R$", "FRETE ( - ) R$"], ["Nº (    ) PAX BUG R$", "GUIA ( - ) R$"], ["RESTAURANTE R$", "CARTÃO R$"],
       ["SUBTOTAL R$", "TOTAL R$"]].each_with_index do |(esquerda, direita), i|
        y = bounds.top - i * 15
        text_box limpo(esquerda), at: [10, y], width: 120, size: 8, style: :bold
        stroke_horizontal_line 125, 230, at: y - 9
        text_box limpo(direita), at: [260, y], width: 90, size: 8, style: :bold
        stroke_horizontal_line 345, 440, at: y - 9
      end
      observacoes_da_ordem(470)
    end
  end

  def observacoes_da_ordem(x)
    text_box "Observ.:", at: [x, bounds.top], size: 8, style: :bold
    text_box limpo(@sorder.sobservacoes), at: [x + 40, bounds.top], width: bounds.width - x - 170, height: 30, size: 7,
                                         overflow: :shrink_to_fit
  end

  def passageiro(item)
    acompanhantes = @config[:acompanhantes] ? item.companions.to_a : []
    observacao = limpo(item.comments).strip
    coluna_obs = @config.fetch(:observacao, :hotel)
    largura_obs = @config[:observacao] == :cod ? @colunas[:cod] + @colunas[:nome_pax] : @colunas[coluna_obs] - 4
    altura_obs = observacao.empty? ? 0 : height_of(observacao, width: largura_obs, size: 6) + 2

    if @config[:acompanhantes] == :linha
      lista = acompanhantes.map { |pessoa| descrever(pessoa) }.join(", ")
      altura_lista = lista.empty? ? 0 : height_of(lista, width: @colunas[:nome_pax] - 4, size: 7) + 2
      abaixo = altura_lista + altura_obs # model 7 puts the notes under the pax list
    else
      altura_lista = acompanhantes.size * LINHA_ACOMPANHANTE + (@config[:regua_acompanhantes] && acompanhantes.any? ? 4 : 0)
      abaixo = [altura_lista, altura_obs].max
    end
    abaixo += 10 if @config[:forma_pagamento]
    altura = [LINHA_TITULAR + abaixo + 5, @config.fetch(:altura_minima, 0)].max
    bounds.move_past_bottom if cursor < altura
    topo = cursor

    stroke_horizontal_line 0, bounds.width, at: topo
    y = topo - 2
    @colunas.each_key { |coluna| celula(coluna, valor_da_coluna(coluna, item), y) }
    y -= LINHA_TITULAR

    case @config[:acompanhantes]
    when :linha
      text_box limpo(lista), at: [@x[:nome_pax] + 2, y], width: @colunas[:nome_pax] - 4, height: altura_lista, size: 7 unless lista.empty?
      text_box observacao, at: [0, y - altura_lista], width: largura_obs, height: altura_obs, size: 6 unless observacao.empty?
    when :lista
      if @config[:regua_acompanhantes] && acompanhantes.any?
        stroke_horizontal_line 0, bounds.width, at: y + 1
        y -= 4
      end
      text_box observacao, at: [@x[coluna_obs] + 2, y], width: largura_obs, height: altura_obs, size: 6 unless observacao.empty?
      coluna_documento = @config.fetch(:documento_acompanhante, :documento)
      acompanhantes.each_with_index do |pessoa, i|
        linha = y - i * LINHA_ACOMPANHANTE
        celula(:titular, descrever(pessoa), linha, size: 7)
        celula(coluna_documento, documento(pessoa), linha, size: 7, align: :left)
      end
    else
      text_box observacao, at: [@x[coluna_obs] + 2, y], width: largura_obs, height: altura_obs, size: 6 unless observacao.empty?
    end

    if @config[:forma_pagamento] && item.nome_forma_pagamento
      text_box "Forma Pagto= #{limpo(item.nome_forma_pagamento)}", at: [bounds.width - 200, topo - altura + 12], width: 195,
                                                                     size: 8, align: :right
    end
    move_cursor_to topo - altura
  end

  def valor_da_coluna(coluna, item)
    case coluna
    when :hotel then item.hotel&.sname
    when :apto then item.apto
    when :titular, :nome_pax then [item.nome_passageiro, situacao(item)].compact_blank.join(" ")
    when :documento, :identidade then documento(item)
    when :cod_cliente, :cod then codigo_cliente(item)
    when :telefone then item.phone
    when :pax then item.qtdepax.to_i
    when :chd then item.qtdechd.to_i
    when :colo then item.companions.count(&:colo?)
    when :hora then item.hour
    when :valor then valor(item.total_passeio)
    when :solicitante then item.vendor&.sname
    when :repassado then item.agency&.sname
    end
  end

  def situacao(item)
    return "(CANCELADO)" if item.cancelado?

    "(repassado)" if item.agency_id && !@colunas.key?(:repassado)
  end

  def descrever(pessoa)
    [pessoa.snome, ("(CHD)" if pessoa.chd?), ("(colo)" if pessoa.colo?)].compact.join(" ")
  end

  def documento(registro)
    [registro.documenttype, registro.document].compact_blank.join(" ")
  end

  # SISTGER's customer code when the customer was imported, else ours.
  def codigo_cliente(item)
    codigo = item.customer&.sistger_id || item.customer_id
    codigo && number_with_delimiter(codigo, delimiter: ".")
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

  def celula(coluna, conteudo, y, size: nil, style: :normal, align: nil)
    return unless @colunas.key?(coluna)

    size ||= MENORES.include?(coluna) ? 7 : 9
    direita = A_DIREITA.include?(coluna)
    # Right-aligned numbers keep a gap before the next column.
    largura = @colunas[coluna] - (direita ? 8 : 4)
    text_box limpo(conteudo), at: [@x[coluna] + 2, y], width: largura, height: size + 3, size: size, style: style,
                              align: align || (direita ? :right : :left), overflow: :shrink_to_fit, min_font_size: 5
  end

  def valor(numero)
    number_with_precision(numero.to_d, precision: 2, delimiter: ".", separator: ",")
  end

  # The built-in PDF fonts only cover Windows-1252; anything else becomes "?".
  def limpo(texto)
    texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
