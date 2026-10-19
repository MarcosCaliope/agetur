class SorderPdf < Prawn::Document
    def initialize(sorders)
        super()
        @sorders = sorders.order("data Desc").all
        @totais_pax = Sorder.totais_pax(@sorders)
        #text "Hello there"
        sorder_id
    end
    def sorder_id
        table sorder_id_all do
            #row(0).font_style = :bold
            #columns(1..3).align = :right
            #columns(4).width = 150
            self.row_colors = ["DDDDDD", "FFFFFF"]
            self.header = true
        end
    end
    
    def sorder_id_all
    [["id", "Destino", "Guia", "Motorista", "Veículo", "Data", "PAX", "CHD"]] +
        @sorders.map do |s|
            pax, chd = @totais_pax.fetch(s.id, [0, 0])
            [s.id, s.destination.description, s.tourguide.sname, s.driver.sname, s.vehicle.license, s.data&.strftime('%d/%m/%Y'), pax, chd]
        end

    end
end