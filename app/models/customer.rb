class Customer < ApplicationRecord
    belongs_to :state, optional: true
end
