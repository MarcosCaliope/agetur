class CreateHotels < ActiveRecord::Migration[5.2]
  def change
    create_table :hotels do |t|
      t.string :sname
      t.string :email
      t.string :address
      t.string :phone
      t.string :comments
      t.float :Valordiaria

      t.timestamps
    end
  end
end
