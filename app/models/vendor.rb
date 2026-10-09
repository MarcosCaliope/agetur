class Vendor < ApplicationRecord
  include Pesquisavel
  pesquisavel_por :sname, :short_name, :document, :email, :phone, :phone2, :contact, :city, :classification

  belongs_to :state, optional: true
  has_many :vendor_destinations, dependent: :delete_all

  scope :ativos, -> { where(active: true) }
end
