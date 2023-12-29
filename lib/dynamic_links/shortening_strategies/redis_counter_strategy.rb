require 'redis'

module DynamicLinks
  module ShorteningStrategies
    class RedisCounterStrategy < BaseStrategy
      REDIS_COUNTER_KEY = "dynamic_links:counter".freeze
      MIN_LENGTH = 12

      def initialize
        # TODO: use pool of connections
        @redis = Redis.new
      end

      # Shortens the given URL using a Redis counter
      # @param url [String] The URL to shorten
      # @return [String] The shortened URL, 12 characters long
      def shorten(url)
        # Increment the counter in Redis
        counter = @redis.incr(REDIS_COUNTER_KEY)

        # Convert the counter value to a Base62 string
        base62_encode("#{counter}#{url.hash.abs}".to_i)
      end
    end
  end
end

