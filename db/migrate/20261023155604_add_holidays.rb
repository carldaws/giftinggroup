class AddHolidays < ActiveRecord::Migration[8.1]
  def change
    create_table :group_holidays do |t|
      t.references :group, null: false, foreign_key: true, index: false
      t.string :key, null: false

      t.timestamps
    end
    add_index :group_holidays, [ :group_id, :key ], unique: true
    add_index :group_holidays, :key

    create_table :group_holiday_recipients do |t|
      t.references :group_holiday, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :group_holiday_recipients, [ :group_holiday_id, :user_id ], unique: true

    add_column :occasions, :holiday_key, :string
    add_index :occasions, [ :holiday_key, :date ], unique: true, where: "holiday_key IS NOT NULL"

    remove_check_constraint :occasions, "(group_id IS NULL) <> (person_id IS NULL)", name: "occasions_belong_to_a_group_or_a_person"
    add_check_constraint :occasions, "num_nonnulls(group_id, person_id, holiday_key) = 1", name: "occasions_belong_to_one_thing"
  end
end
