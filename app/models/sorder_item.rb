class SorderItem < ApplicationRecord
  belongs_to :sorder
  belongs_to :customer
  belongs_to :hotel
  belongs_to :vendor

end
