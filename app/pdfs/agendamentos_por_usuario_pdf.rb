# Agendamentos por usuário (AgendamentosPorUsuario) in A4 portrait, like
# SISTGER's printout: a row per passenger under each user, with the user's
# count, and the grand total.
class AgendamentosPorUsuarioPdf < Prawn::Document
  include PdfFormatacao

  def initialize(relatorio, empresa)
    super(page_size: "A4", margin: 28)
    @relatorio = relatorio

    cabecalho_empresa(empresa)
    text limpo(relatorio.titulo), size: 11, style: :bold, align: :center
    move_down 8
    tabela
    if relatorio.sem_usuario.positive?
      move_down 6
      text "#{relatorio.sem_usuario} passageiro(s) do período sem usuário registrado.", size: 8, style: :italic
    end
    number_pages "<page>/<total>", at: [bounds.right - 50, 0], width: 50, align: :right, size: 8
  end

  private

  def tabela
    linhas = [["Usuário", "Data OS", "OS", "Passageiro", "Hotel", "Data gravação"]]
    destaques, totais = [], []
    @relatorio.grupos.each do |usuario, itens|
      destaques << linhas.size
      linhas << [{ content: limpo(usuario), colspan: 6 }]
      itens.each do |item|
        nome = item.cancelado? ? "#{item.nome_passageiro} (cancelado)" : item.nome_passageiro
        linhas << [usuario, data(item.sorder.data), number_with_delimiter(item.sorder_id, delimiter: "."), nome,
                   item.hotel&.sname, data(AgendamentosPorUsuario.gravado_em(item))].map { |texto| limpo(texto) }
      end
      totais << linhas.size
      linhas << [{ content: "Total do usuário: #{itens.size}", colspan: 6 }]
    end
    if @relatorio.itens.empty?
      linhas << [{ content: "Nenhum passageiro lançado por usuário no período.", colspan: 6 }]
    else
      totais << linhas.size
      linhas << [{ content: "Total geral: #{@relatorio.itens.size}", colspan: 6 }]
    end

    table linhas, width: bounds.width, header: true, column_widths: { 0 => 95, 1 => 55, 2 => 40, 5 => 60 },
                  cell_style: { size: 8, padding: [2, 3], borders: [] } do |t|
      t.row(0).font_style = :bold
      t.row(0).borders = [:bottom]
      t.columns(2).align = :right
      destaques.each { |linha| t.row(linha).font_style = :bold }
      destaques.each { |linha| t.row(linha).background_color = "EEEEEE" }
      totais.each { |linha| t.row(linha).font_style = :bold }
      totais.each { |linha| t.row(linha).borders = [:top] }
    end
  end

  # The built-in PDF fonts only cover Windows-1252; anything else becomes "?".
  def limpo(texto)
    texto.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
