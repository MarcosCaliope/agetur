class AddStateToCustomer < ActiveRecord::Migration[5.2]
  def change
    add_reference :customers, :state, foreign_key: true
  end
end
