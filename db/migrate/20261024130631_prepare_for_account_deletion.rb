class PrepareForAccountDeletion < ActiveRecord::Migration[8.1]
  def change
    change_column_null :messages, :author_id, true
    add_column :messages, :author_name, :string
    add_column :items, :released_by_name, :string
  end
end
