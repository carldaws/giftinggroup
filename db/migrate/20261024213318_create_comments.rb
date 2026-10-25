class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :item, null: false, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
      t.string :author_name
      t.text :body, null: false
      t.timestamps
    end
  end
end
