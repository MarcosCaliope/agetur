class SorderItem < ApplicationRecord
  belongs_to :sorder
  belongs_to :customer, optional: true
  belongs_to :hotel, optional: true
  belongs_to :vendor, optional: true

end
