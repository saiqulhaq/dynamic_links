class AddUniqueIndexToShortenedUrls < ActiveRecord::Migration[7.1]
  def change
    add_index :dynamic_links_shortened_urls, [:client_id, :short_url], unique: true
  end
end
