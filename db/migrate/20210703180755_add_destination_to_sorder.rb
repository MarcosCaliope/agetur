class AddDestinationToSorder < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorders, :destination, foreign_key: true
  end
end
