class AddAvatarToneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_tone, :integer
  end
end
