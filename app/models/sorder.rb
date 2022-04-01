class Sorder < ApplicationRecord
    has_many :sorder_items #, inverse_of: :sorders
    accepts_nested_attributes_for :sorder_items, reject_if: :all_blank, allow_destroy: true
    belongs_to :destination
    belongs_to :tourguide
    belongs_to :company
    belongs_to :driver
    belongs_to :vehicle
    
    def total_pax
       #User.includes(:posts).where('posts.name = ?', 'example')
        #Sorder.includes(:sorder_items).where('sorder_items.scancelado = ?', 'N').references(:sorder_items)
        sorder_items.where('sorder_items.scancelado = ?', 'N').sum("qtdepax")
    end

    def total_chd
       #Sorder.includes(:sorder_items)
       sorder_items.where('sorder_items.scancelado = ?', 'N').sum("qtdechd")
    end
    
end
