class CreateTourguides < ActiveRecord::Migration[5.2]
  def change
    create_table :tourguides do |t|
      t.string :sname
      t.string :email
      t.string :address
      t.string :phone
      t.string :comments

      t.timestamps
    end
  end
end
