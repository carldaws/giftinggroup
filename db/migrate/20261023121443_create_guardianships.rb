class CreateGuardianships < ActiveRecord::Migration[8.1]
  def change
    create_table :guardianships do |t|
      t.references :guardian, null: false, foreign_key: { to_table: :users }, index: false
      t.references :dependant, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :guardianships, [ :guardian_id, :dependant_id ], unique: true
  end
end
