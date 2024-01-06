module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Configuration
    attr_accessor :shortening_strategy, :enable_rest_api, :db_infra_strategy,
                  :async_processing, :redis_counter_config, :cache_store_config

    DEFAULT_SHORTENING_STRATEGY = :MD5
    DEFAULT_ENABLE_REST_API = true
    DEFAULT_DB_INFRA_STRATEGY = :standard
    DEFAULT_ASYNC_PROCESSING = false
    DEFAULT_REDIS_COUNTER_CONFIG = -> { RedisConfig.new }
    DEFAULT_CACHE_STORE_CONFIG = { type: nil, redis_config: {}, memcached_config: {} }

    def initialize
      @shortening_strategy = DEFAULT_SHORTENING_STRATEGY
      @enable_rest_api = DEFAULT_ENABLE_REST_API
      @db_infra_strategy = DEFAULT_DB_INFRA_STRATEGY
      @async_processing = DEFAULT_ASYNC_PROCESSING

      # config for RedisCounterStrategy
      @redis_counter_config = DEFAULT_REDIS_COUNTER_CONFIG.call
      @cache_store_config = DEFAULT_CACHE_STORE_CONFIG
    end

    def cache_store_enabled?
      [:redis, :memcached].include?(@cache_store_config[:type])
    end

    def cache_store
      @cache_store ||= begin
                         unless cache_store_enabled?
                           raise ConfigurationError, 'Cache store is not configured'
                         end

                         case config[:type]
                         when :redis
                           DynamicLinks::RedisCacheStore.new(config[:redis_config])
                         when :memcached
                           DynamicLinks::MemcachedCacheStore.new(config[:memcached_config])
                         else
                           raise DynamicLinks::UnknownCacheStoreType, "Unsupported cache store type: #{config[:type]}"
                         end
                       end
    end
  end
end
