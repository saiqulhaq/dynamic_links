module DynamicLinks
  module ShorteningStrategies
    # usage:
    # Using default configuration from DynamicLinks configuration
    # default_strategy = DynamicLinks::ShorteningStrategies::RedisCounterStrategy.new
    #
    # Using a custom configuration
    # custom_redis_config = { host: 'custom-host', port: 6380 }
    # custom_strategy = DynamicLinks::ShorteningStrategies::RedisCounterStrategy.new(custom_redis_config)
    class RedisCounterStrategy < BaseStrategy
      MIN_LENGTH = 12
      REDIS_COUNTER_KEY = "dynamic_links:counter".freeze

      # @param redis_config [Hash]
      def initialize(redis_config = nil)
        super()

        configuration = redis_config.nil? ? DynamicLinks.configuration.redis_counter_config : DynamicLinks::Configuration::RedisConfig.new(redis_config)
        @redis = ConnectionPool.new(size: configuration.pool_size, timeout: configuration.pool_timeout) do
          redis_config = configuration.config
          Redis.new(redis_config)
        end
      end

      def always_growing?
        true  # This strategy always generates a new shortened URL
      end

      # Shortens the given URL using a Redis counter
      # @param url [String] The URL to shorten
      # @return [String] The shortened URL, 12 characters long
      def shorten(url, min_length: MIN_LENGTH)
        @redis.with do |conn|
          counter = conn.incr(REDIS_COUNTER_KEY)
          short_url = base62_encode("#{counter}#{url.hash.abs}".to_i)
          short_url = short_url.ljust(min_length, '0')
          short_url
        end
      end
    end
  end
end

