class AddAvatarCharacterToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_character, :string
  end
end
