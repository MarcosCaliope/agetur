class SorderPdf < Prawn::Document
    def initialize(sorders)
        super()
        @sorders = sorders.order("data Desc").all
        #@q = Sorder.ransack(params[:q])
        #@sorders = @q.result
         
        #text "Hello there"
        sorder_id
    end
    def sorder_id
        table sorder_id_all do
            #row(0).font_style = :bold
            #columns(1..3).align = :right
           # columns(1..6).width = 100
            #columns(4).width = 150
            self.row_colors = ["DDDDDD", "FFFFFF"]
            self.header = true
        end
    end
    
    def sorder_id_all
    [["id", "Destino", "Guia", "Motorista", "Veículo", "Data"]] +
 #       @sorders.map do |sorders|
 #           [sorders.id, sorders.destination.description, sorders.tourguide.sname, sorders.driver.sname, sorders.vehicle.license]
 #       end

        @sorders.map do |s|
            [s.id, s.destination.description, s.tourguide.sname, s.driver.sname, s.vehicle.license, s.data.strftime('%d/%m/%Y')]
        end
    end
end