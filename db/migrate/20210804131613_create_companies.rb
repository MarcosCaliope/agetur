class CreateCompanies < ActiveRecord::Migration[5.2]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :cnpj
      t.string :address
      t.string :phone
      t.string :city
      t.references :state, foreign_key: true
      t.integer :osmodel
      t.integer :osdupla
      t.string :email
      t.string :site
      t.string :logoform
      t.string :logoentrada
      t.integer :iretorno
      t.integer :osshowcan
      t.integer :osshowcanrel
      t.integer :osshowrep
      t.string :osincludechdcalc
      t.string :comments

      t.timestamps
    end
  end
end
