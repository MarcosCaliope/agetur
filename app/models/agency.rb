class Agency < ApplicationRecord
  belongs_to :state, optional: true
  # SISTGER's "Vendedor Correspondente".
  belongs_to :vendor, optional: true
end
