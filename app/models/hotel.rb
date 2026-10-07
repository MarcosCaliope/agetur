class Hotel < ApplicationRecord
  belongs_to :state, optional: true

  def self.ransackable_attributes(auth_object = nil)
    ["sname"]
  end
end
