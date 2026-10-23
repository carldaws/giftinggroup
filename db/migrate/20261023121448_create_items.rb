class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :list, null: false, foreign_key: true
      t.references :suggested_by, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :url
      t.text :notes
      t.string :price
      t.boolean :most_wanted, null: false, default: false
      t.integer :quantity, default: 1
      t.datetime :received_at

      t.timestamps
    end
  end
end
