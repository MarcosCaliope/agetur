class CreateVendors < ActiveRecord::Migration[5.2]
  def change
    create_table :vendors do |t|
      t.string :sname
      t.string :email
      t.string :address
      t.string :phone
      t.string :comments
      t.float :commission

      t.timestamps
    end
  end
end
