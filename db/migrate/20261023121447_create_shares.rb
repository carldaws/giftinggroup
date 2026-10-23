class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares do |t|
      t.references :list, null: false, foreign_key: true, index: false
      t.references :group, null: false, foreign_key: true

      t.timestamps
    end
    add_index :shares, [ :list_id, :group_id ], unique: true
  end
end
