class CreateOccasions < ActiveRecord::Migration[8.1]
  def change
    create_table :occasions do |t|
      t.references :group, null: false, foreign_key: true, index: false
      t.references :person, foreign_key: { to_table: :users }
      t.references :creator, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :name
      t.date :date, null: false

      t.timestamps
    end
    add_index :occasions, [ :group_id, :date ]
    add_index :occasions, [ :group_id, :person_id, :date ], unique: true, where: "person_id IS NOT NULL"
  end
end
