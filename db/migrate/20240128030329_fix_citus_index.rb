class FixCitusIndex < ActiveRecord::Migration[7.1]
  def up
    if DynamicLinks.configuration.db_infra_strategy == :sharding
      # execute SQL to remove primary key constraint
      execute <<-SQL
        ALTER TABLE dynamic_links_shortened_urls
        DROP CONSTRAINT dynamic_links_shortened_urls_pkey;
      SQL

      execute <<-SQL
        ALTER TABLE dynamic_links_shortened_urls
        ADD PRIMARY KEY (id, client_id);
      SQL
      create_distributed_table :dynamic_links_shortened_urls, :client_id
    end
  end

  # this code is untested
  def down
    if DynamicLinks.configuration.db_infra_strategy == :sharding
      drop_distributed_table :dynamic_links_shortened_urls, :client_id

      execute <<-SQL
        ALTER TABLE dynamic_links_shortened_urls
        DROP CONSTRAINT dynamic_links_shortened_urls_pkey;
      SQL

      execute <<-SQL
        ALTER TABLE dynamic_links_shortened_urls
        ADD PRIMARY KEY (id);
      SQL
    end
  end
end
