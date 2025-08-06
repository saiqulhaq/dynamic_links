# frozen_string_literal: true

if Rails.env.test?
  require 'mock_redis'

  # Configure DynamicLinks to use MockRedis for testing
  DynamicLinks.configure do |config|
    # Use MD5 strategy for most tests to avoid Redis dependencies
    config.shortening_strategy = :md5
    config.enable_rest_api = true
    config.async_processing = false
    config.enable_fallback_mode = false

    # Use MockRedis for cache store in tests
    redis_client = MockRedis.new
    cache_store = ActiveSupport::Cache::RedisCacheStore.new(
      redis: redis_client,
      namespace: 'dynamic_links_test'
    )
    config.cache_store = cache_store

    # Configure MockRedis for redis_counter_config
    redis_config = DynamicLinks::RedisConfig.new
    config.redis_counter_config = redis_config
  end

  # Mock Redis.new to return MockRedis instances
  Redis.define_singleton_method(:new) do |*args|
    MockRedis.new
  end
end