class CreateDynamicLinksShortenedUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :dynamic_links_shortened_urls, id: false do |t|
      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        t.bigserial :id, primary_key: true
      else
        t.bigint :id, primary_key: true
      end

      t.references :client, null: true, foreign_key: { to_table: :dynamic_links_clients }, type: :bigint
      t.string :url, null: false, limit: 2083
      t.string :short_url, null: false, limit: 10
      t.datetime :expires_at
      t.timestamps
    end

    add_index :dynamic_links_shortened_urls, :short_url, unique: true
  end
end
