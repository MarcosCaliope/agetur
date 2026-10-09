class Hotel < ApplicationRecord
  include Pesquisavel
  pesquisavel_por :sname, :short_name, :document, :email, :phone, :phone2, :contact, :city

  belongs_to :state, optional: true

  def self.ransackable_attributes(auth_object = nil)
    ["sname"]
  end
end
