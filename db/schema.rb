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

ActiveRecord::Schema[7.1].define(version: 2024_01_03_155651) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dynamic_links_clients", force: :cascade do |t|
    t.string "name", null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hostname", null: false
    t.string "scheme", default: "https", null: false
    t.index ["api_key"], name: "index_dynamic_links_clients_on_api_key", unique: true
    t.index ["hostname"], name: "index_dynamic_links_clients_on_hostname", unique: true
    t.index ["name"], name: "index_dynamic_links_clients_on_name", unique: true
  end

  create_table "dynamic_links_shortened_urls", force: :cascade do |t|
    t.bigint "client_id"
    t.string "url", limit: 2083, null: false
    t.string "short_url", limit: 20, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "short_url"], name: "index_dynamic_links_shortened_urls_on_client_id_and_short_url", unique: true
    t.index ["client_id"], name: "index_dynamic_links_shortened_urls_on_client_id"
  end

  add_foreign_key "dynamic_links_shortened_urls", "dynamic_links_clients", column: "client_id"
end
