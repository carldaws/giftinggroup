class CreateInterestsAndSizes < ActiveRecord::Migration[8.1]
  def change
    create_table :interests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    create_table :sizes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :label, null: false
      t.string :value, null: false

      t.timestamps
    end
  end
end
