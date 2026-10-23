class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.references :item, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.datetime :bought_at

      t.timestamps
    end
    add_index :reservations, [ :item_id, :user_id ], unique: true
  end
end
