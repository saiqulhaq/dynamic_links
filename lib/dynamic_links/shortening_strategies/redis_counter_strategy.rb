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

      def initialize(redis_config = nil)
        super()
        pool_size = DynamicLinks.configuration.redis_pool_size
        pool_timeout = DynamicLinks.configuration.redis_pool_timeout

        @redis = ConnectionPool.new(size: pool_size, timeout: pool_timeout) do
          redis_config = redis_config.presence || DynamicLinks.configuration.redis_config
          Redis.new(redis_config)
        end
      end

      # Shortens the given URL using a Redis counter
      # @param url [String] The URL to shorten
      # @return [String] The shortened URL, 12 characters long
      def shorten(url, min_length: MIN_LENGTH)
        short_url = nil
        @redis.with do |conn|
          counter = conn.incr(REDIS_COUNTER_KEY)
          short_url = base62_encode("#{counter}#{url.hash.abs}".to_i)
          short_url.ljust(min_length, '0')
        end
        short_url
      end
    end
  end
end

