class AddTourguideToSorder < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorders, :tourguide, foreign_key: true
  end
end
