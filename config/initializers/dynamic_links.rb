DynamicLinks.configure do |config|
  # Shortening strategy: :md5 (default), :nanoid, :redis_counter, :sha256, etc.
  config.shortening_strategy = :md5

  # Enable or disable the REST API endpoints
  config.enable_rest_api = true

  # Database infrastructure strategy: :standard, :sharding, or :citus (auto if CITUS_ENABLED)
  config.db_infra_strategy = :standard
  # config.db_infra_strategy = :citus if ENV['CITUS_ENABLED'].to_s == 'true'

  # Asynchronous processing for shortening (uses ActiveJob)
  # config.async_processing = true

  # Redis configuration for advanced strategies (optional)
  # config.redis_config = { host: 'localhost', port: 6379 }
  # config.redis_pool_size = 10
  # config.redis_pool_timeout = 3

  # Fallback mode: redirect to Firebase if short link not found locally
  config.enable_fallback_mode = false
  config.firebase_host = "https://example.app.goo.gl"

  # Example cache store (using Redis)
  cache_store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0/cache'),
    namespace: 'dynamic_links'
  )
  config.cache_store = cache_store
end
