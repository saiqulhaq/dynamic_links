# frozen_string_literal: true

DynamicLinks.configure do |config|
  # Shortening strategy: :md5 (default), :nanoid, :redis_counter, :sha256, etc.
  config.shortening_strategy = :nanoid

  # Enable or disable the REST API endpoints
  config.enable_rest_api = true

  # Asynchronous processing for shortening (uses ActiveJob)
  # config.async_processing = true

  # Redis configuration for advanced strategies (optional)
  # config.redis_config = { host: 'localhost', port: 6379 }
  # config.redis_pool_size = 10
  # config.redis_pool_timeout = 3

  # Fallback mode: redirect to Firebase if short link not found locally
  config.enable_fallback_mode = ENV.fetch('FALLBACK_MODE', 'false') == 'true'
  config.firebase_host = ENV.fetch('FIREBASE_HOST', 'https://your-firebase-project.firebaseio.com')

  # Example cache store (using Redis)
  cache_store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    namespace: 'dynamic_links'
  )
  config.cache_store = cache_store
end
