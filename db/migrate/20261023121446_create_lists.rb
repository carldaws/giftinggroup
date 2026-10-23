class CreateLists < ActiveRecord::Migration[8.1]
  def change
    create_table :lists do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false

      t.timestamps
    end
  end
end
