module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>

  class Configuration
    attr_accessor :shortening_strategy, :enable_rest_api, :db_infra_strategy,
                  :async_processing, :redis_counter_config, :cache_store

    DEFAULT_SHORTENING_STRATEGY = :MD5
    DEFAULT_ENABLE_REST_API = true
    DEFAULT_DB_INFRA_STRATEGY = :standard
    DEFAULT_ASYNC_PROCESSING = false
    DEFAULT_REDIS_COUNTER_CONFIG = RedisConfig.new
    # use any class that extends ActiveSupport::Cache::Store, default is MemoryStore
    DEFAULT_CACHE_STORE = ActiveSupport::Cache::MemoryStore.new

    # Usage:
    #     DynamicLinks.configure do |config|
    #       config.shortening_strategy = :MD5 # or other strategy name, see StrategyFactory for available strategies
    #       config.enable_rest_api = true # or false. when false, the API requests will be rejected
    #       config.db_infra_strategy = :standard # or :sharding. if sharding is used, then xxx
    #       config.async_processing = false # or true. if true, the shortening process will be done asynchronously using ActiveJob
    #       config.redis_counter_config = RedisConfig.new # see RedisConfig documentation for more details
    #       # if you use Redis
    #       config.cache_store = ActiveSupport::Cache::RedisStore.new('redis://localhost:6379/0/cache')
    #       # if you use Memcached
    #       config.cache_store = ActiveSupport::Cache::MemCacheStore.new('localhost:11211')
    #     end
    #
    # @return [Configuration]
    def initialize
      @shortening_strategy = DEFAULT_SHORTENING_STRATEGY
      @enable_rest_api = DEFAULT_ENABLE_REST_API
      @db_infra_strategy = DEFAULT_DB_INFRA_STRATEGY
      @async_processing = DEFAULT_ASYNC_PROCESSING

      # config for RedisCounterStrategy
      @redis_counter_config = DEFAULT_REDIS_COUNTER_CONFIG
      @cache_store = DEFAULT_CACHE_STORE
    end
  end
end
