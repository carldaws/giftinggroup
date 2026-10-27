class AddSplits < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :split_with, :integer

    create_table :shares do |t|
      t.references :reservation, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.timestamps

      t.index %i[ reservation_id user_id ], unique: true
    end
  end
end
