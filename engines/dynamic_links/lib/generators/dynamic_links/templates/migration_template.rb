# frozen_string_literal: true

class AddAvailableToShortenedUrls < ActiveRecord::Migration[7.1]
  def change
    add_column :dynamic_links_shortened_urls, :available, :boolean, null: false, default: true
    add_index :dynamic_links_shortened_urls, :available
  end
end
