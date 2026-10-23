class CreateReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :readings do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :membership, null: false, foreign_key: true
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :readings, %i[ user_id membership_id ], unique: true
  end
end
