class GiveEachPersonOneList < ActiveRecord::Migration[8.1]
  def up
    add_reference :items, :owner, foreign_key: { to_table: :users }
    add_column :items, :little, :boolean, null: false, default: false

    execute <<~SQL
      UPDATE items SET owner_id = lists.owner_id FROM lists WHERE lists.id = items.list_id
    SQL

    change_column_null :items, :owner_id, false
    remove_reference :items, :list, foreign_key: true
    drop_table :shares
    drop_table :lists
  end

  def down
    create_table :lists do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.timestamps
    end

    create_table :shares do |t|
      t.references :list, null: false, foreign_key: true, index: false
      t.references :group, null: false, foreign_key: true
      t.timestamps
    end
    add_index :shares, [ :list_id, :group_id ], unique: true

    add_reference :items, :list, foreign_key: true

    execute <<~SQL
      INSERT INTO lists (owner_id, name, created_at, updated_at)
      SELECT DISTINCT owner_id, 'Wishlist', NOW(), NOW() FROM items
    SQL
    execute <<~SQL
      UPDATE items SET list_id = lists.id FROM lists WHERE lists.owner_id = items.owner_id
    SQL
    execute <<~SQL
      INSERT INTO shares (list_id, group_id, created_at, updated_at)
      SELECT lists.id, memberships.group_id, NOW(), NOW()
      FROM lists JOIN memberships ON memberships.user_id = lists.owner_id
    SQL

    change_column_null :items, :list_id, false
    remove_column :items, :little
    remove_reference :items, :owner, foreign_key: { to_table: :users }
  end
end
