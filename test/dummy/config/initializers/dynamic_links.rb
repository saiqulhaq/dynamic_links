DynamicLinks.configure do |config|
  config.shortening_strategy = ENV['SHORTENING_STRATEGY'].to_sym
  config.enable_rest_api = true
  if ENV['CITUS_ENABLED'].to_s == 'true'
    config.db_infra_strategy = :citus
  end

  config.redis_counter_config.pool_size = 5
  config.redis_counter_config.pool_timeout = 5
  config.redis_counter_config.config = {
    host: ENV['REDIS_HOST'] || 'localhost',
    port: ENV['REDIS_PORT'] || 6379,
    db: ENV['REDIS_DB'] || 0,
  }
end
