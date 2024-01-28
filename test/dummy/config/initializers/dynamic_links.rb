DynamicLinks.configure do |config|
  config.shortening_strategy = ENV['SHORTENING_STRATEGY'].to_sym
  config.enable_rest_api = true
  if ENV['CITUS_ENABLED'].to_s == 'true'
    config.db_infra_strategy = :sharding
  end

  config.redis_counter_config.pool_size = 5
  config.redis_counter_config.pool_timeout = 5
  config.redis_counter_config.config = {
    host: ENV.fetch('REDIS_HOST', 'localhost'),
    port: ENV.fetch('REDIS_PORT', 6379).to_i,
    db: ENV.fetch('REDIS_DB', 0).to_i,
  }
end
