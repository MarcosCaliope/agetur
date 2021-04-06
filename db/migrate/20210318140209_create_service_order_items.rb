class CreateServiceOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :service_order_items do |t|
      t.references :service_order, foreign_key: true
      t.string :nomepax
      t.string :documenttype
      t.string :document
      t.references :hotel, foreign_key: true
      t.string :apto
      t.integer :qtdepax
      t.string :hour
      t.string :phone
      t.references :vendor, foreign_key: true
      t.references :agency, foreign_key: true
      t.float :amount
      t.float :amountpay
      t.float :amountcomission
      t.string :comments

      t.timestamps
    end
  end
end
