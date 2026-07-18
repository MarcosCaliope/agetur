class HotelPdf < Prawn::Document
    def initialize(hotels)
        super()
        @hotel = hotels.order("id Desc").all
        #text "Hello there"
        hotel_id
    end
    def hotel_id
        table hotel_id_all do
            row(0).font_style = :bold
            #columns(1..3).align = :right
            columns(1..2).width = 150
            #columns(4).width = 150
            self.row_colors = ["DDDDDD", "FFFFFF"]
            self.header = true
        end
    end
    
    def hotel_id_all
    [["id", "Nome", "endereço", "Fone", "email", "Observações"]] +
        @hotel.map do |hotels|
            [hotels.id, hotels.sname,hotels.address, hotels.phone, hotels.email, hotels.comments]
        end

    end
end