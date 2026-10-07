class Hotel < ApplicationRecord
  def self.ransackable_attributes(auth_object = nil)
    ["sname"]
  end
end
