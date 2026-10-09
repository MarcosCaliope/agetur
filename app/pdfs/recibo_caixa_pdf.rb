# Receipt of a cash book entry (SISTGER's ReciboCaixa and, for a batch of
# commissions, the vendor's receipt from frmRelRecibo).
class ReciboCaixaPdf < Prawn::Document
  include PdfFormatacao

  def initialize(lancamento, empresa)
    super(page_size: "A4")
    @lancamento = lancamento
    @empresa = empresa
    cabecalho_empresa(empresa)
    titulo
    corpo
    comissoes if lancamento.payables.any?
    assinatura
  end

  private

  def titulo
    text "RECIBO Nº #{@lancamento.id}", size: 16, style: :bold, align: :center
    text moeda(@lancamento.valor), size: 14, style: :bold, align: :right
    move_down 15
  end

  def corpo
    pagador, recebedor = if @lancamento.entrada?
                           [@lancamento.requerente.presence || "—", @empresa&.name]
                         else
                           [@empresa&.name, @lancamento.requerente.presence || "—"]
                         end
    documento = " (#{@lancamento.documento})" if @lancamento.documento.present? && @lancamento.entrada?
    text "#{@lancamento.entrada? ? 'Recebemos' : 'Recebi'} de #{pagador}#{documento} a importância de " \
         "#{moeda(@lancamento.valor)}, referente a: #{@lancamento.descricao}.", leading: 4
    move_down 6
    text "Forma de pagamento: #{@lancamento.nome_forma}."
    move_down 15
    @recebedor = recebedor
  end

  def comissoes
    linhas = @lancamento.payables.includes(sorder_item: :sorder, sorder: :destination).order(:sorder_id, :id).map do |conta|
      ordem = conta.sorder
      [ordem&.id.to_s, ordem&.data ? data(ordem.data) : "", ordem&.destination&.description.to_s,
       conta.sorder_item&.nome_passageiro.to_s, moeda(conta.valor_pago)]
    end
    table [["OS", "Data", "Roteiro", "Passageiro", "Valor"]] + linhas + [["", "", "", "Total", moeda(@lancamento.valor)]],
          width: bounds.width, cell_style: { size: 9 } do
      row(0).font_style = :bold
      row(-1).font_style = :bold
      columns(4).align = :right
      self.header = true
    end
    move_down 15
  end

  def assinatura
    text [@empresa&.city.presence, data(@lancamento.data, format: :long)].compact.join(", "), align: :right
    move_down 45
    stroke_horizontal_line bounds.width / 4, bounds.width * 3 / 4
    move_down 4
    text @recebedor.to_s, align: :center
  end
end
