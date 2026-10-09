class Driver < ApplicationRecord
  include Pesquisavel
  pesquisavel_por :sname, :short_name, :document, :email, :phone, :phone2, :contact, :city

  belongs_to :state, optional: true
  has_many :sorders
end
