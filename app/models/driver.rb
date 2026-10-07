class Driver < ApplicationRecord
  belongs_to :state, optional: true
  has_many :sorders
end
