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

ActiveRecord::Schema[7.1].define(version: 2025_05_10_064807) do
  create_schema "sql_stat_statement"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

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

  create_table "attachments", force: :cascade do |t|
    t.bigint "folder_id"
    t.string "file_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_type", default: "undefined"
    t.string "b2_key"
    t.string "byte_size"
    t.integer "file_monitor_id"
    t.boolean "in_bins"
    t.index ["file_monitor_id"], name: "index_attachments_on_file_monitor_id"
    t.index ["folder_id"], name: "index_attachments_on_folder_id"
    t.index ["in_bins"], name: "index_attachments_on_in_bins"
  end

  create_table "attachments_shares", id: false, force: :cascade do |t|
    t.bigint "attachment_id"
    t.bigint "share_id"
    t.boolean "top"
    t.index ["attachment_id"], name: "index_attachments_shares_on_attachment_id"
    t.index ["share_id"], name: "index_attachments_shares_on_share_id"
  end

  create_table "file_monitors", force: :cascade do |t|
    t.integer "owner_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "b2_key"
    t.index ["b2_key"], name: "index_file_monitors_on_b2_key", unique: true
  end

  create_table "folders", force: :cascade do |t|
    t.bigint "user_id"
    t.string "folder_name"
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "numbering"
    t.boolean "in_bins"
    t.index ["ancestry"], name: "index_folders_on_ancestry"
    t.index ["in_bins"], name: "index_folders_on_in_bins"
    t.index ["numbering"], name: "index_folders_on_numbering"
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "folders_shares", id: false, force: :cascade do |t|
    t.bigint "folder_id"
    t.bigint "share_id"
    t.boolean "top"
    t.index ["folder_id"], name: "index_folders_shares_on_folder_id"
    t.index ["share_id"], name: "index_folders_shares_on_share_id"
  end

  create_table "recycle_bins", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "mix_id"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_top"
    t.index ["user_id"], name: "index_recycle_bins_on_user_id"
  end

  create_table "shares", force: :cascade do |t|
    t.string "link"
    t.string "varify"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["link"], name: "index_shares_on_link"
    t.index ["user_id"], name: "index_shares_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "status", default: "active"
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.integer "access_count_to_reset_password_page", default: 0
    t.string "activation_state"
    t.string "activation_token"
    t.datetime "activation_token_expires_at"
    t.decimal "total_space", precision: 12
    t.decimal "used_space", precision: 12
    t.string "phone"
    t.index ["activation_token"], name: "index_users_on_activation_token"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_me_token"], name: "index_users_on_remember_me_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
