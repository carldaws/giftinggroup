class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.string :join_code, null: false

      t.timestamps
    end
    add_index :groups, :join_code, unique: true
  end
end
