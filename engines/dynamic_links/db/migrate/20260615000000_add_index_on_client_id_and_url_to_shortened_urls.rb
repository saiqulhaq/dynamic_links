# frozen_string_literal: true

# Adds an index on (client_id, url) so DynamicLinks.find_short_link and
# the find_or_create controller action can look up an existing short URL
# for a client in O(log n) instead of doing a sequential scan on the
# varchar(2083) url column. Also speeds up redirects that key off the
# long URL (e.g., the analytics engine join on url).
#
# Uses CONCURRENTLY to avoid taking an ACCESS EXCLUSIVE lock on
# dynamic_links_shortened_urls during creation. Requires
# `disable_ddl_transaction!` and must NOT run inside a transaction
# (e.g., the production deploy script should run db:migrate normally,
# not wrapped in a manual transaction).
class AddIndexOnClientIdAndUrlToShortenedUrls < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    safety_settings!
    add_index :dynamic_links_shortened_urls, %i[client_id url],
              name: 'index_dynamic_links_shortened_urls_on_client_id_and_url',
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :dynamic_links_shortened_urls,
                 name: 'index_dynamic_links_shortened_urls_on_client_id_and_url',
                 algorithm: :concurrently,
                 if_exists: true
  end

  private

  # Configure Postgres session for a long-running non-blocking index build.
  # Each SET is local to the current connection that runs the migration.
  def safety_settings!
    return unless connection.adapter_name.match?(/postgres/i)

    connection.execute("SET maintenance_work_mem = '1GB';")
    connection.execute("SET statement_timeout = '30min';")
    connection.execute("SET lock_timeout = '0ms';")
  end
end
