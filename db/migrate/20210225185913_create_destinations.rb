class CreateDestinations < ActiveRecord::Migration[5.2]
  def change
    create_table :destinations do |t|
      t.string :description
      t.integer :distance
      t.float :valuenormal
      t.float :valuenormalchd
      t.float :valuenet
      t.float :valuenetchd
      t.float :valuecard
      t.float :valuecardchd
      t.references :state, foreign_key: true

      t.timestamps
    end
  end
end
