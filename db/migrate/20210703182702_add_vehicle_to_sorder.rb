class AddVehicleToSorder < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorders, :vehicle, foreign_key: true
  end
end
