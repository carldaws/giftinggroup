class MakeBirthdaysOnePerPerson < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM occasions WHERE person_id IS NOT NULL"

    remove_index :occasions, [ :group_id, :person_id, :date ]
    change_column_null :occasions, :group_id, true
    add_index :occasions, [ :person_id, :date ], unique: true, where: "person_id IS NOT NULL"
    add_check_constraint :occasions, "(group_id IS NULL) <> (person_id IS NULL)", name: "occasions_belong_to_a_group_or_a_person"
  end

  def down
    execute "DELETE FROM occasions WHERE person_id IS NOT NULL"

    remove_check_constraint :occasions, name: "occasions_belong_to_a_group_or_a_person"
    remove_index :occasions, [ :person_id, :date ]
    change_column_null :occasions, :group_id, false
    add_index :occasions, [ :group_id, :person_id, :date ], unique: true, where: "person_id IS NOT NULL"
  end
end
