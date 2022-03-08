class AddDriverToSorder < ActiveRecord::Migration[5.2]
  def change
    add_reference :sorders, :driver, foreign_key: true
  end
end
