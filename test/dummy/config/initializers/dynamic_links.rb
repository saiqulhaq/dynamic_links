DynamicLinks.configure do |config|
  config.shortening_strategy = :MD5

  config.redis_config = {
    host: "redis",    # Redis server host
    port: 6379,           # Redis server port
    db: 1,                # Redis database to use
  }
end
