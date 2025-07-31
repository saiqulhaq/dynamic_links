# frozen_string_literal: true

class ChangeClientIdToNotNullInShortenedUrls < ActiveRecord::Migration[8.0]
  def change
    # Add null: false constraint to client_id in dynamic_links_shortened_urls table
    # This ensures data integrity as all shortened URLs must belong to a client
    change_column_null :dynamic_links_shortened_urls, :client_id, false
  end
end
