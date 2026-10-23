class AddBirthdayToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :birthday_month, :integer
    add_column :users, :birthday_day, :integer
    add_column :users, :birth_year, :integer
  end
end
