class Customer < ApplicationRecord
    belongs_to :state, optional: true
    has_many :sorder_item
end
