class CreateSorderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :sorder_items do |t|
      t.references :sorder, foreign_key: true
      t.string :comments

      t.timestamps
    end
  end
end
