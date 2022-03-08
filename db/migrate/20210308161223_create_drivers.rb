class CreateDrivers < ActiveRecord::Migration[5.2]
  def change
    create_table :drivers do |t|
      t.string :sname
      t.string :email
      t.string :address
      t.string :phone
      t.string :city
      t.string :comments

      t.timestamps
    end
  end
end
