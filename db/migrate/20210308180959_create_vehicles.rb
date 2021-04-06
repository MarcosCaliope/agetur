class CreateVehicles < ActiveRecord::Migration[5.2]
  def change
    create_table :vehicles do |t|
      t.string :license
      t.string :brand
      t.string :smodel
      t.string :year
      t.string :color
      t.string :city
      t.references :state, foreign_key: true
      t.string :comments

      t.timestamps
    end
  end
end
