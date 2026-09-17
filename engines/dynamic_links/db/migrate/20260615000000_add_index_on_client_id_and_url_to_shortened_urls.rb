# frozen_string_literal: true

# Adds an index on (client_id, url) so DynamicLinks.find_short_link and
# the find_or_create controller action can look up an existing short URL
# for a client in O(log n) instead of doing a sequential scan on the
# varchar(2083) url column.
#
# Uses CONCURRENTLY to avoid taking an ACCESS EXCLUSIVE lock on
# dynamic_links_shortened_urls during creation. Requires
# `disable_ddl_transaction!` and must NOT run inside a transaction
# (e.g., the production deploy script should run db:migrate normally,
# not wrapped in a manual transaction).
class AddIndexOnClientIdAndUrlToShortenedUrls < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
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
end
