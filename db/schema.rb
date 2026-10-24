# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_24_213318) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "author_id"
    t.string "author_name"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["item_id"], name: "index_comments_on_item_id"
  end
  
  create_table "group_holiday_recipients", force: :cascade do |t|
    t.bigint "group_holiday_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_holiday_id", "user_id"], name: "index_group_holiday_recipients_on_group_holiday_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_group_holiday_recipients_on_user_id"
  end

  create_table "group_holidays", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "key"], name: "index_group_holidays_on_group_id_and_key", unique: true
    t.index ["key"], name: "index_group_holidays_on_key"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "join_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["join_code"], name: "index_groups_on_join_code", unique: true
  end

  create_table "guardianships", force: :cascade do |t|
    t.bigint "guardian_id", null: false
    t.bigint "dependant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dependant_id"], name: "index_guardianships_on_dependant_id"
    t.index ["guardian_id", "dependant_id"], name: "index_guardianships_on_guardian_id_and_dependant_id", unique: true
  end

  create_table "interests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_interests_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "suggested_by_id"
    t.string "name"
    t.string "url"
    t.text "notes"
    t.string "price"
    t.boolean "most_wanted", default: false, null: false
    t.integer "quantity", default: 1
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "owner_id", null: false
    t.boolean "little", default: false, null: false
    t.datetime "removed_at"
    t.string "released_by_name"
    t.index ["owner_id"], name: "index_items_on_owner_id"
    t.index ["suggested_by_id"], name: "index_items_on_suggested_by_id"
    t.check_constraint "name IS NOT NULL OR url IS NOT NULL", name: "items_have_a_name_or_link"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_memberships_on_group_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "subject_id"
    t.bigint "author_id"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "author_name"
    t.bigint "group_id", null: false
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["group_id"], name: "index_messages_on_group_id"
    t.index ["subject_id"], name: "index_messages_on_subject_id"
  end

  create_table "occasion_recipients", force: :cascade do |t|
    t.bigint "occasion_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occasion_id", "user_id"], name: "index_occasion_recipients_on_occasion_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_occasion_recipients_on_user_id"
  end

  create_table "occasions", force: :cascade do |t|
    t.bigint "group_id"
    t.bigint "person_id"
    t.bigint "creator_id"
    t.string "name"
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "for_everyone", default: true, null: false
    t.string "holiday_key"
    t.index ["creator_id"], name: "index_occasions_on_creator_id"
    t.index ["group_id", "date"], name: "index_occasions_on_group_id_and_date"
    t.index ["holiday_key", "date"], name: "index_occasions_on_holiday_key_and_date", unique: true, where: "(holiday_key IS NOT NULL)"
    t.index ["person_id", "date"], name: "index_occasions_on_person_id_and_date", unique: true, where: "(person_id IS NOT NULL)"
    t.index ["person_id"], name: "index_occasions_on_person_id"
    t.check_constraint "num_nonnulls(group_id, person_id, holiday_key) = 1", name: "occasions_belong_to_one_thing"
  end

  create_table "readings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "membership_id"
    t.datetime "read_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "group_id", null: false
    t.index ["group_id"], name: "index_readings_on_group_id"
    t.index ["membership_id"], name: "index_readings_on_membership_id"
    t.index ["user_id", "group_id"], name: "index_readings_on_user_id_and_group_id_for_group_chats", unique: true, where: "(membership_id IS NULL)"
    t.index ["user_id", "membership_id"], name: "index_readings_on_user_id_and_membership_id", unique: true
  end

  create_table "reservations", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.bigint "user_id", null: false
    t.datetime "bought_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "occasion_id"
    t.index ["item_id", "user_id"], name: "index_reservations_on_item_id_and_user_id", unique: true
    t.index ["occasion_id"], name: "index_reservations_on_occasion_id"
    t.index ["user_id"], name: "index_reservations_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sizes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "label", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sizes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.integer "avatar_tone"
    t.integer "birthday_month"
    t.integer "birthday_day"
    t.integer "birth_year"
    t.string "avatar_character"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "items"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "group_holiday_recipients", "group_holidays"
  add_foreign_key "group_holiday_recipients", "users"
  add_foreign_key "group_holidays", "groups"
  add_foreign_key "guardianships", "users", column: "dependant_id"
  add_foreign_key "guardianships", "users", column: "guardian_id"
  add_foreign_key "interests", "users"
  add_foreign_key "items", "users", column: "owner_id"
  add_foreign_key "items", "users", column: "suggested_by_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "groups"
  add_foreign_key "messages", "memberships", column: "subject_id"
  add_foreign_key "messages", "users", column: "author_id"
  add_foreign_key "occasion_recipients", "occasions"
  add_foreign_key "occasion_recipients", "users"
  add_foreign_key "occasions", "groups"
  add_foreign_key "occasions", "users", column: "creator_id", on_delete: :nullify
  add_foreign_key "occasions", "users", column: "person_id"
  add_foreign_key "readings", "groups"
  add_foreign_key "readings", "memberships"
  add_foreign_key "readings", "users"
  add_foreign_key "reservations", "items"
  add_foreign_key "reservations", "occasions", on_delete: :nullify
  add_foreign_key "reservations", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "sizes", "users"
end
