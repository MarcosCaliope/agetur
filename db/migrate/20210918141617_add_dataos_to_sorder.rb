class AddDataosToSorder < ActiveRecord::Migration[5.2]
  def change
    add_column :sorders, :dataos, :datetime
  end
end
