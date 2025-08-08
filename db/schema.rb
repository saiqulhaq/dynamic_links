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

ActiveRecord::Schema[8.0].define(version: 2025_08_08_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "dynamic_links_analytics_link_clicks", force: :cascade do |t|
    t.string "short_url", null: false
    t.text "original_url", null: false
    t.string "client_id"
    t.inet "ip_address", null: false
    t.datetime "clicked_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "((metadata ->> 'referrer'::text))", name: "idx_link_clicks_referrer"
    t.index "((metadata ->> 'referrer'::text))", name: "idx_link_clicks_referrer_not_null", where: "(((metadata ->> 'referrer'::text) IS NOT NULL) AND ((metadata ->> 'referrer'::text) <> ''::text))"
    t.index "((metadata ->> 'user_agent'::text))", name: "idx_link_clicks_user_agent"
    t.index "((metadata ->> 'utm_campaign'::text))", name: "idx_link_clicks_utm_campaign"
    t.index "((metadata ->> 'utm_campaign'::text))", name: "idx_link_clicks_utm_campaign_not_null", where: "(((metadata ->> 'utm_campaign'::text) IS NOT NULL) AND ((metadata ->> 'utm_campaign'::text) <> ''::text))"
    t.index "((metadata ->> 'utm_medium'::text))", name: "idx_link_clicks_utm_medium"
    t.index "((metadata ->> 'utm_source'::text))", name: "idx_link_clicks_utm_source"
    t.index "((metadata ->> 'utm_source'::text))", name: "idx_link_clicks_utm_source_not_null", where: "(((metadata ->> 'utm_source'::text) IS NOT NULL) AND ((metadata ->> 'utm_source'::text) <> ''::text))"
    t.index ["clicked_at"], name: "idx_link_clicks_clicked_at"
    t.index ["client_id", "clicked_at"], name: "idx_link_clicks_client_id_clicked_at"
    t.index ["client_id"], name: "idx_link_clicks_client_id"
    t.index ["ip_address"], name: "idx_link_clicks_ip_address"
    t.index ["metadata"], name: "idx_link_clicks_metadata_gin", using: :gin
    t.index ["short_url", "clicked_at"], name: "idx_link_clicks_short_url_clicked_at"
    t.index ["short_url", "ip_address"], name: "idx_link_clicks_short_url_ip"
    t.index ["short_url"], name: "idx_link_clicks_short_url"
  end

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
    t.bigint "client_id", null: false
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
