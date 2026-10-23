class ReplaceMagicLinksWithPasswords < ActiveRecord::Migration[8.1]
  def change
    drop_table :magic_links do |t|
      t.string :email_address, null: false, index: true
      t.string :code, null: false
      t.string :token, null: false, index: { unique: true }
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :expires_at, null: false, index: true

      t.timestamps
    end

    add_column :users, :password_digest, :string
  end
end
