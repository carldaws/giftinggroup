class CreateMagicLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :magic_links do |t|
      t.string :email_address, null: false
      t.string :code, null: false
      t.string :token, null: false
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :magic_links, :token, unique: true
    add_index :magic_links, :email_address
    add_index :magic_links, :expires_at
  end
end
