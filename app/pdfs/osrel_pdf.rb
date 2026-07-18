class OsrelPdf < Prawn::Document
    def initialize(serviceorders)
        super()
        @service_orders = serviceorders.order("id Desc").all
        serviceorder_id
    end
    def serviceorder_id
        table serviceorder_id_all do
            row(0).font_style = :bold
            #columns(1..3).align = :right
            columns(1..4).width = 150
            #columns(4).width = 150
            self.row_colors = ["DDDDDD", "FFFFFF"]
            self.header = true
        end
    end
    
    def serviceorder_id_all
    [["id", "Destino", "Data"]] +
        @service_orders.map do |service_orders|
            [service_orders.id, service_orders.destination.description]
        end

    end
end