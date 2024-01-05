module DynamicLinks
  class Configuration
    attr_accessor :shortening_strategy, :enable_rest_api, :db_infra_strategy,
                  :async_processing, :cache_store,
                  :redis_counter_config,
                  :cache_store_config

    def initialize
      @shortening_strategy = :MD5  # Default strategy
      @enable_rest_api = true  # Enable REST API by default
      @db_infra_strategy = :standard  # Default DB infrastructure strategy (:standard, :citus)
      @async_processing = false

      # config for RedisCounterStrategy
      @redis_counter_config = RedisConfig.new

      @cache_store_config = { type: nil, redis_config: {}, memcached_config: {} }
    end

    def cache_store_enabled?
      !@cache_store_config[:type].nil?
    end

    class RedisConfig
      attr_accessor :config, :pool_size, :pool_timeout

      def initialize
        # Default to an empty hash, can be overridden
        @config = {
          # host: 'localhost',
          # port: 6379
        }
        @pool_size = 5          # Default pool size
        @pool_timeout = 5       # Default timeout in seconds
      end
    end
  end
end
