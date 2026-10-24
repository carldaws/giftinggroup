class AllowItemsWithOnlyALink < ActiveRecord::Migration[8.1]
  def change
    change_column_null :items, :name, true
    add_check_constraint :items, "name IS NOT NULL OR url IS NOT NULL", name: "items_have_a_name_or_link"
  end
end
