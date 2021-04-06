class CreateCustomers < ActiveRecord::Migration[5.2]
  def change
    create_table :customers do |t|
      t.string :nome
      t.string :email
      t.string :phone
      t.string :document
      t.string :comments
      t.string :city

      t.timestamps
    end
  end
end
