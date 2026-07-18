class Vehicle < ApplicationRecord
  belongs_to :state
  has_many :sorders
end
