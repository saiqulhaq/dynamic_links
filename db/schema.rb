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

ActiveRecord::Schema[8.0].define(version: 20_250_801_155_408) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'ahoy_events', force: :cascade do |t|
    t.bigint 'ahoy_visits_id'
    t.string 'name'
    t.jsonb 'properties'
    t.datetime 'time'
    t.index ['ahoy_visits_id'], name: 'index_ahoy_events_on_ahoy_visits_id'
    t.index %w[name time], name: 'index_ahoy_events_on_name_and_time'
    t.index ['properties'], name: 'index_ahoy_events_on_properties', opclass: :jsonb_path_ops, using: :gin
  end

  create_table 'ahoy_visits', force: :cascade do |t|
    t.string 'visit_token'
    t.string 'visitor_token'
    t.string 'ip'
    t.text 'user_agent'
    t.text 'referrer'
    t.string 'referring_domain'
    t.text 'landing_page'
    t.string 'browser'
    t.string 'os'
    t.string 'device_type'
    t.string 'country'
    t.string 'region'
    t.string 'city'
    t.float 'latitude'
    t.float 'longitude'
    t.string 'utm_source'
    t.string 'utm_medium'
    t.string 'utm_term'
    t.string 'utm_content'
    t.string 'utm_campaign'
    t.string 'app_version'
    t.string 'os_version'
    t.string 'platform'
    t.datetime 'started_at'
    t.bigint 'dynamic_links_shortened_urls_id'
    t.index ['dynamic_links_shortened_urls_id'], name: 'index_ahoy_visits_on_dynamic_links_shortened_urls_id'
    t.index ['visit_token'], name: 'index_ahoy_visits_on_visit_token', unique: true
    t.index %w[visitor_token started_at], name: 'index_ahoy_visits_on_visitor_token_and_started_at'
  end

  create_table 'dynamic_links_clients', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'api_key', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'hostname', null: false
    t.string 'scheme', default: 'https', null: false
    t.index ['api_key'], name: 'index_dynamic_links_clients_on_api_key', unique: true
    t.index ['hostname'], name: 'index_dynamic_links_clients_on_hostname', unique: true
    t.index ['name'], name: 'index_dynamic_links_clients_on_name', unique: true
  end

  create_table 'dynamic_links_shortened_urls', force: :cascade do |t|
    t.bigint 'client_id', null: false
    t.string 'url', limit: 2083, null: false
    t.string 'short_url', limit: 20, null: false
    t.datetime 'expires_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[client_id short_url], name: 'index_dynamic_links_shortened_urls_on_client_id_and_short_url',
                                     unique: true
    t.index ['client_id'], name: 'index_dynamic_links_shortened_urls_on_client_id'
  end

  add_foreign_key 'dynamic_links_shortened_urls', 'dynamic_links_clients', column: 'client_id'
end
