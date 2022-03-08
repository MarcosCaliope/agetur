class State < ApplicationRecord
    has_many :customers
    belongs_to :company
end
