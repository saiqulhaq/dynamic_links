
module DynamicLinks
  module ShorteningStrategies
    class RedisCounterStrategy < BaseStrategy
      begin
        require 'redis'
      rescue LoadError
        raise 'Missing dependency: Please add "redis" to your Gemfile to use RedisCounterStrategy.'
      end

      MIN_LENGTH = 12
      REDIS_COUNTER_KEY = "dynamic_links:counter".freeze

      def initialize
        # TODO: use pool of connections
        @redis = Redis.new
      end

      # Shortens the given URL using a Redis counter
      # @param url [String] The URL to shorten
      # @return [String] The shortened URL, 12 characters long
      def shorten(url, min_length: MIN_LENGTH)
        counter = @redis.incr(REDIS_COUNTER_KEY)

        short_url = base62_encode("#{counter}#{url.hash.abs}".to_i)
        short_url.ljust(min_length, '0')
      end
    end
  end
end

