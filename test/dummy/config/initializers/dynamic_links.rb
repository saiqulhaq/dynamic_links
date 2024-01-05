DynamicLinks.configure do |config|
  config.shortening_strategy = :md5
  config.enable_rest_api = true

  config.redis_counter_config.pool_size = 5
  config.redis_counter_config.pool_timeout = 5
  config.redis_counter_config.config = {
    host: "redis",
    port: 6379,
    db: 1,
  }
end
