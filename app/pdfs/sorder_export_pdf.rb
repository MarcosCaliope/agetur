class SorderExportPdf < Prawn::Document
    def initialize(sorder)
        super(page_size: "A4", page_layout: :landscape)
        @sorder = sorder
        header
        move_down 15
        items
    end

    def header
        company = @sorder.company
        text company.name.to_s, size: 16, style: :bold
        text [company.address, company.city, company.phone].compact_blank.join(" - "), size: 9
        text [("CNPJ: #{company.cnpj}" if company.cnpj.present?), company.email, company.site].compact_blank.join(" - "), size: 9
        move_down 10
        text "Ordem de Serviço No. #{@sorder.id}", size: 14, style: :bold
        text "Data: #{@sorder.data&.strftime('%d/%m/%Y')}   Destino: #{@sorder.destination.description}"
        text "Guia: #{@sorder.tourguide.sname}   Motorista: #{@sorder.driver.sname}   Veículo: #{@sorder.vehicle.license}"
        text "Observações: #{@sorder.sobservacoes}" if @sorder.sobservacoes.present?
    end

    def items
        table items_rows, width: bounds.width do
            row(0).font_style = :bold
            self.row_colors = ["DDDDDD", "FFFFFF"]
            self.header = true
        end
    end

    def items_rows
    [["Hotel", "Apto", "Passageiro/Titular", "Documento", "Telefone", "PAX", "CHD", "Valor", "Solicitante", "Observações"]] +
        @sorder.sorder_items.map do |item|
            [item.hotel&.sname, item.apto, item.customer&.nome, [item.documenttype, item.document].compact_blank.join(" "),
             item.phone, item.qtdepax, item.qtdechd, item.amount, item.vendor&.sname, item.comments].map(&:to_s)
        end
    end
end
