class Customer < ApplicationRecord
    belongs_to :state, optional: true
    belongs_to :billing_state, class_name: "State", optional: true
    has_many :sorder_items
end
