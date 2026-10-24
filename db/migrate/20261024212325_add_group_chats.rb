class AddGroupChats < ActiveRecord::Migration[8.1]
  def up
    add_reference :messages, :group, foreign_key: true
    add_reference :readings, :group, foreign_key: true

    execute "UPDATE messages SET group_id = memberships.group_id FROM memberships WHERE memberships.id = messages.subject_id"
    execute "UPDATE readings SET group_id = memberships.group_id FROM memberships WHERE memberships.id = readings.membership_id"

    change_column_null :messages, :group_id, false
    change_column_null :readings, :group_id, false
    change_column_null :messages, :subject_id, true
    change_column_null :readings, :membership_id, true

    add_index :readings, %i[ user_id group_id ], unique: true, where: "membership_id IS NULL", name: "index_readings_on_user_id_and_group_id_for_group_chats"
  end

  def down
    execute "DELETE FROM readings WHERE membership_id IS NULL"
    execute "DELETE FROM messages WHERE subject_id IS NULL"

    remove_index :readings, name: "index_readings_on_user_id_and_group_id_for_group_chats"
    change_column_null :readings, :membership_id, false
    change_column_null :messages, :subject_id, false

    remove_reference :readings, :group, foreign_key: true
    remove_reference :messages, :group, foreign_key: true
  end
end
