# Passeios repassados (PasseiosRepassados) in A4 landscape: a row per
# passenger under each agency, with the agency's totals, and the grand total.
class PasseiosRepassadosPdf < Prawn::Document
  include PdfFormatacao

  COLUNAS = 9

  def initialize(relatorio, empresa)
    super(page_size: "A4", page_layout: :landscape, margin: 28)
    @relatorio = relatorio

    cabecalho_empresa(empresa)
    text limpo(relatorio.titulo), size: 11, style: :bold, align: :center
    move_down 8
    tabela
    number_pages "<page>/<total>", at: [bounds.right - 50, 0], width: 50, align: :right, size: 8
  end

  private

  def tabela
    linhas = [["Data OS", "OS", "Roteiro", "Passageiro", "Hotel / Apto", "A receber", "Comissão repasse", "Paga", "A pagar"]]
    destaques, totais = [], []
    @relatorio.grupos.each do |agencia, itens|
      destaques << linhas.size
      linhas << [{ content: limpo(agencia.sname), colspan: COLUNAS }]
      itens.each do |item|
        nome = item.cancelado? ? "#{item.nome_passageiro} (cancelado)" : item.nome_passageiro
        linhas << [data(item.sorder.data), number_with_delimiter(item.sorder_id, delimiter: "."),
                   item.sorder.destination&.description, nome, [item.hotel&.sname, item.apto.presence].compact.join(" / "),
                   moeda(item.total_passeio), moeda(item.amountcomissionrep.to_f), moeda(item.amountcomissionreppay.to_f),
                   moeda(item.comissao_repasse_a_pagar)].map { |texto| limpo(texto) }
      end
      totais << linhas.size
      linhas << linha_total("Total da agência", PasseiosRepassados.totais(itens))
    end
    if @relatorio.itens.empty?
      linhas << [{ content: "Nenhum passeio repassado no período.", colspan: COLUNAS }]
    else
      totais << linhas.size
      linhas << linha_total("Total geral", @relatorio.totais)
    end

    table linhas, width: bounds.width, header: true,
                  column_widths: { 0 => 55, 1 => 40, 5 => 65, 6 => 75, 7 => 65, 8 => 65 },
                  cell_style: { size: 8, padding: [2, 3], borders: [] } do |t|
      t.row(0).font_style = :bold
      t.row(0).borders = [:bottom]
      t.columns(1).align = :right
      t.columns(5..8).align = :right
      destaques.each { |linha| t.row(linha).font_style = :bold }
      destaques.each { |linha| t.row(linha).background_color = "EEEEEE" }
      totais.each { |linha| t.row(linha).font_style = :bold }
      totais.each { |linha| t.row(linha).borders = [:top] }
    end
  end

  def linha_total(rotulo, totais)
    [{ content: "#{rotulo}: #{totais[:quantidade]} passageiro(s)", colspan: 5 },
     *totais.values_at(:a_receber, :comissao, :paga, :a_pagar).map { |valor| moeda(valor) }]
  end

  # The built-in PDF fonts only cover Windows-1252; anything else becomes "?".
  def limpo(texto)
    texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
