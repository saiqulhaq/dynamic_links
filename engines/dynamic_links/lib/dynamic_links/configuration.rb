# frozen_string_literal: true

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class Configuration
    attr_reader :shortening_strategy, :enable_rest_api,
                :async_processing, :redis_counter_config, :cache_store,
                :enable_fallback_mode, :firebase_host, :allowed_redirect_hosts

    DEFAULT_SHORTENING_STRATEGY = :md5
    DEFAULT_ENABLE_REST_API = true
    DEFAULT_ASYNC_PROCESSING = false
    DEFAULT_REDIS_COUNTER_CONFIG = RedisConfig.new
    # use any class that extends ActiveSupport::Cache::Store, default is MemoryStore
    DEFAULT_CACHE_STORE = ActiveSupport::Cache::MemoryStore.new
    DEFAULT_ENABLE_FALLBACK_MODE = false
    DEFAULT_FIREBASE_HOST = nil
    DEFAULT_ALLOWED_REDIRECT_HOSTS = [].freeze # Empty array means no host restrictions

    # Usage:
    #     DynamicLinks.configure do |config|
    #       config.shortening_strategy = :md5 # or other strategy name, see StrategyFactory for available strategies
    #       config.enable_rest_api = true # or false. when false, the API requests will be rejected
    #       config.async_processing = false # or true. if true, the shortening process will be done asynchronously using ActiveJob
    #       config.redis_counter_config = RedisConfig.new # see RedisConfig documentation for more details
    #       # if you use Redis
    #       config.cache_store = ActiveSupport::Cache::RedisCacheStore.new(url: 'redis://localhost:6379/0')
    #       # if you use Memcached
    #       config.cache_store = ActiveSupport::Cache::MemCacheStore.new('localhost:11211')
    #       config.allowed_redirect_hosts = ['example.com', 'www.example.com', 'subdomain.example.com']
    #     end
    #
    # @return [Configuration]
    def initialize
      @shortening_strategy = DEFAULT_SHORTENING_STRATEGY
      @enable_rest_api = DEFAULT_ENABLE_REST_API
      @async_processing = DEFAULT_ASYNC_PROCESSING
      # config for RedisCounterStrategy
      @redis_counter_config = DEFAULT_REDIS_COUNTER_CONFIG
      @cache_store = DEFAULT_CACHE_STORE
      @enable_fallback_mode = DEFAULT_ENABLE_FALLBACK_MODE
      @firebase_host = DEFAULT_FIREBASE_HOST
      @allowed_redirect_hosts = DEFAULT_ALLOWED_REDIRECT_HOSTS.dup
    end

    def shortening_strategy=(strategy)
      unless StrategyFactory::VALID_SHORTENING_STRATEGIES.include?(strategy)
        raise ArgumentError,
              "Invalid shortening strategy, provided strategy: #{strategy}. Valid strategies are: #{StrategyFactory::VALID_SHORTENING_STRATEGIES.join(', ')}"
      end

      @shortening_strategy = strategy
    end

    def enable_rest_api=(value)
      raise ArgumentError, 'enable_rest_api must be a boolean' unless [true, false].include?(value)

      @enable_rest_api = value
    end

    def async_processing=(value)
      raise ArgumentError, 'async_processing must be a boolean' unless [true, false].include?(value)

      @async_processing = value
    end

    def redis_counter_config=(config)
      raise ArgumentError, 'redis_counter_config must be an instance of RedisConfig' unless config.is_a?(RedisConfig)

      @redis_counter_config = config
    end

    def cache_store=(store)
      unless store.is_a?(ActiveSupport::Cache::Store)
        raise ArgumentError, 'cache_store must be an instance of ActiveSupport::Cache::Store'
      end

      @cache_store = store
    end

    def enable_fallback_mode=(value)
      raise ArgumentError, 'enable_fallback_mode must be a boolean' unless [true, false].include?(value)

      @enable_fallback_mode = value
    end

    def firebase_host=(host)
      # allow nil or blank host (optional, depends on your app logic)
      if host.nil? || host.strip.empty?
        @firebase_host = nil
        return
      end

      begin
        uri = URI.parse(host.to_s)
        valid = uri.is_a?(URI::HTTP) && uri.host.present?
        raise unless valid
      rescue StandardError
        raise ArgumentError, 'firebase_host must be a valid URL with a host'
      end

      @firebase_host = host
    end

    def allowed_redirect_hosts=(hosts)
      if hosts.nil?
        @allowed_redirect_hosts = DEFAULT_ALLOWED_REDIRECT_HOSTS.dup
        return
      end

      raise ArgumentError, 'allowed_redirect_hosts must be an array of strings' unless hosts.is_a?(Array)

      # Validate each host in the array
      hosts.each do |host|
        unless host.is_a?(String) && host.strip.present?
          raise ArgumentError, 'All allowed_redirect_hosts must be non-empty strings'
        end
      end

      @allowed_redirect_hosts = hosts.map(&:downcase).freeze
    end
  end
end
