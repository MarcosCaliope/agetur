# The cash book for a period (SISTGER's ResumoCaixa): entries, balance and
# totals per payment method.
class ResumoCaixaPdf < Prawn::Document
  include PdfFormatacao

  def initialize(inicio, fim, empresa)
    super(page_size: "A4", page_layout: :landscape)
    periodo = CashEntry.where(data: inicio..fim)
    @lancamentos = periodo.order(:data, :id)
    @saldo_anterior = CashEntry.where(data: ...inicio).saldo
    @entradas = periodo.entradas.sum(:valor)
    @saidas = periodo.saidas.sum(:valor)
    @por_forma = periodo.group(:forma_pagamento, :tipo).sum(:valor)

    cabecalho_empresa(empresa)
    text "Resumo do caixa: #{inicio == fim ? data(inicio) : "#{data(inicio)} a #{data(fim)}"}", size: 14, style: :bold
    move_down 8
    resumo
    move_down 10
    lancamentos
    move_down 10
    formas
  end

  private

  def resumo
    table [["Saldo anterior", "Entradas", "Saídas", "Saldo final"],
           [moeda(@saldo_anterior), moeda(@entradas), moeda(-@saidas), moeda(@saldo_anterior + @entradas - @saidas)]],
          cell_style: { size: 10 } do
      row(0).font_style = :bold
    end
  end

  def lancamentos
    linhas = @lancamentos.map do |l|
      [l.id.to_s, data(l.data), l.categoria, l.descricao, l.nome_forma, (moeda(l.valor) if l.entrada?).to_s,
       (moeda(l.valor) unless l.entrada?).to_s]
    end
    linhas = [["", "", "", "Nenhum lançamento no período.", "", "", ""]] if linhas.empty?
    table [["Nº", "Data", "Categoria", "Descrição", "Forma", "Entrada", "Saída"]] + linhas,
          width: bounds.width, cell_style: { size: 8 } do
      row(0).font_style = :bold
      columns(5..6).align = :right
      self.row_colors = ["FFFFFF", "F2F2F2"]
      self.header = true
    end
  end

  def formas
    linhas = CashEntry::FORMAS.filter_map do |forma, nome|
      entradas, saidas = @por_forma[[forma, "E"]], @por_forma[[forma, "S"]]
      [nome, moeda(entradas.to_d), moeda(saidas.to_d)] if entradas || saidas
    end
    return if linhas.empty?

    text "Por forma de pagamento", style: :bold
    table [["Forma", "Entradas", "Saídas"]] + linhas, cell_style: { size: 9 } do
      row(0).font_style = :bold
      columns(1..2).align = :right
    end
  end
end
