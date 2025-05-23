module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Configuration
    attr_reader :shortening_strategy, :enable_rest_api, :db_infra_strategy,
                  :async_processing, :redis_counter_config, :cache_store,
                  :enable_fallback_mode, :firebase_host

    VALID_DB_INFRA_STRATEGIES = [:standard, :sharding].freeze

    DEFAULT_SHORTENING_STRATEGY = :nano_id
    DEFAULT_ENABLE_REST_API = true
    DEFAULT_DB_INFRA_STRATEGY = :standard
    DEFAULT_ASYNC_PROCESSING = false
    DEFAULT_REDIS_COUNTER_CONFIG = RedisConfig.new
    # use any class that extends ActiveSupport::Cache::Store, default is MemoryStore
    DEFAULT_CACHE_STORE = ActiveSupport::Cache::MemoryStore.new
    DEFAULT_ENABLE_FALLBACK_MODE = false
    DEFAULT_FIREBASE_HOST = nil

    # Usage:
    #     DynamicLinks.configure do |config|
    #       config.shortening_strategy = :md5 # or other strategy name, see StrategyFactory for available strategies
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
      @enable_fallback_mode = DEFAULT_ENABLE_FALLBACK_MODE
      @firebase_host = DEFAULT_FIREBASE_HOST
    end

    def shortening_strategy=(strategy)
      raise ArgumentError, "Invalid shortening strategy" unless StrategyFactory::VALID_SHORTENING_STRATEGIES.include?(strategy)
      @shortening_strategy = strategy
    end

    def enable_rest_api=(value)
      raise ArgumentError, "enable_rest_api must be a boolean" unless [true, false].include?(value)
      @enable_rest_api = value
    end

    def db_infra_strategy=(strategy)
      raise ArgumentError, "Invalid DB infra strategy" unless VALID_DB_INFRA_STRATEGIES.include?(strategy)
      @db_infra_strategy = strategy
    end

    def async_processing=(value)
      raise ArgumentError, "async_processing must be a boolean" unless [true, false].include?(value)
      @async_processing = value
    end

    def redis_counter_config=(config)
      raise ArgumentError, "redis_counter_config must be an instance of RedisConfig" unless config.is_a?(RedisConfig)
      @redis_counter_config = config
    end

    def cache_store=(store)
      raise ArgumentError, "cache_store must be an instance of ActiveSupport::Cache::Store" unless store.is_a?(ActiveSupport::Cache::Store)
      @cache_store = store
    end

    def enable_fallback_mode=(value)
      raise ArgumentError, "enable_fallback_mode must be a boolean" unless [true, false].include?(value)
      @enable_fallback_mode = value
    end

    def firebase_host=(host)
      raise ArgumentError, "firebase_host must be a valid URL" unless host =~ /\A#{URI::regexp(['http', 'https'])}\z/
      @firebase_host = host
    end
  end
end
