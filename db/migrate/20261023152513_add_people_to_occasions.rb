class AddPeopleToOccasions < ActiveRecord::Migration[8.1]
  def change
    add_column :occasions, :for_everyone, :boolean, null: false, default: true

    create_table :occasion_recipients do |t|
      t.references :occasion, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :occasion_recipients, [ :occasion_id, :user_id ], unique: true
  end
end
