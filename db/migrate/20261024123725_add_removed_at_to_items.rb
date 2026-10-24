class AddRemovedAtToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :removed_at, :datetime
  end
end
