class CreateDynamicLinksAnalyticsLinkClicks < ActiveRecord::Migration[7.0]
  def up
    # Enable pg_stat_statements extension for query performance monitoring
    enable_extension 'pg_stat_statements' unless extension_enabled?('pg_stat_statements')

    create_table :dynamic_links_analytics_link_clicks do |t|
      t.string :short_url, null: false
      t.text :original_url, null: false
      t.string :client_id
      t.inet :ip_address, null: false
      t.datetime :clicked_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    # Primary indexes for performance
    add_index :dynamic_links_analytics_link_clicks, :short_url, name: 'idx_link_clicks_short_url'
    add_index :dynamic_links_analytics_link_clicks, :client_id, name: 'idx_link_clicks_client_id'
    add_index :dynamic_links_analytics_link_clicks, :clicked_at, name: 'idx_link_clicks_clicked_at'
    add_index :dynamic_links_analytics_link_clicks, :ip_address, name: 'idx_link_clicks_ip_address'

    # Composite indexes for common query patterns
    add_index :dynamic_links_analytics_link_clicks, %i[short_url clicked_at],
              name: 'idx_link_clicks_short_url_clicked_at'
    add_index :dynamic_links_analytics_link_clicks, %i[client_id clicked_at],
              name: 'idx_link_clicks_client_id_clicked_at'
    add_index :dynamic_links_analytics_link_clicks, %i[short_url ip_address], name: 'idx_link_clicks_short_url_ip'

    # JSONB indexes for metadata queries
    add_index :dynamic_links_analytics_link_clicks, :metadata, using: :gin, name: 'idx_link_clicks_metadata_gin'

    # Specific JSONB key indexes for common UTM and referrer queries
    add_index :dynamic_links_analytics_link_clicks, "(metadata ->> 'utm_source')", name: 'idx_link_clicks_utm_source'
    add_index :dynamic_links_analytics_link_clicks, "(metadata ->> 'utm_medium')", name: 'idx_link_clicks_utm_medium'
    add_index :dynamic_links_analytics_link_clicks, "(metadata ->> 'utm_campaign')",
              name: 'idx_link_clicks_utm_campaign'
    add_index :dynamic_links_analytics_link_clicks, "(metadata ->> 'referrer')", name: 'idx_link_clicks_referrer'
    add_index :dynamic_links_analytics_link_clicks, "(metadata ->> 'user_agent')", name: 'idx_link_clicks_user_agent'

    # Partial indexes for non-null UTM parameters (more efficient for analytics queries)
    add_index :dynamic_links_analytics_link_clicks,
              "(metadata ->> 'utm_source')",
              where: "metadata ->> 'utm_source' IS NOT NULL AND metadata ->> 'utm_source' != ''",
              name: 'idx_link_clicks_utm_source_not_null'

    add_index :dynamic_links_analytics_link_clicks,
              "(metadata ->> 'utm_campaign')",
              where: "metadata ->> 'utm_campaign' IS NOT NULL AND metadata ->> 'utm_campaign' != ''",
              name: 'idx_link_clicks_utm_campaign_not_null'

    add_index :dynamic_links_analytics_link_clicks,
              "(metadata ->> 'referrer')",
              where: "metadata ->> 'referrer' IS NOT NULL AND metadata ->> 'referrer' != ''",
              name: 'idx_link_clicks_referrer_not_null'
  end

  def down
    drop_table :dynamic_links_analytics_link_clicks
    # NOTE: We don't disable pg_stat_statements as it might be used by other parts of the application
  end
end
