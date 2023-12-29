class CreateDynamicLinksShortenedUrls < ActiveRecord::Migration[7.1]
  def up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<-SQL
        CREATE TABLE dynamic_links_shortened_urls (
          id BIGSERIAL NOT NULL,
          client_id BIGINT,
          url VARCHAR(2083) NOT NULL,
          short_url VARCHAR(10) NOT NULL,
          expires_at TIMESTAMP,
          created_at TIMESTAMP,
          updated_at TIMESTAMP,
          PRIMARY KEY (id, client_id),
          FOREIGN KEY (client_id) REFERENCES dynamic_links_clients(id)
        ) PARTITION BY HASH (client_id);
      SQL

      # Additional logic for creating individual partitions if necessary
    else
      create_table :dynamic_links_shortened_urls do |t|
        t.references :client, null: true, foreign_key: { to_table: :dynamic_links_clients }
        # TODO: make the limit to read from a config file/constant
        t.string :short_url, null: false, limit: 10
        t.string :url, null: false, limit: 2083 # Limit based on typical browser/server constraints
        t.datetime :expires_at
        t.timestamps
      end
    end

    add_index :dynamic_links_shortened_urls, :short_url, unique: true
  end

  def down
    drop_table :dynamic_links_shortened_urls
  end
end
