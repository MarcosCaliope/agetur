class AddCompanyToSorder < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorders, :company, foreign_key: true
  end
end
