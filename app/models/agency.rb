class Agency < ApplicationRecord
  include Pesquisavel
  pesquisavel_por :sname, :short_name, :document, :email, :phone, :phone2, :contact, :city

  belongs_to :state, optional: true
  # SISTGER's "Vendedor Correspondente".
  belongs_to :vendor, optional: true
end
