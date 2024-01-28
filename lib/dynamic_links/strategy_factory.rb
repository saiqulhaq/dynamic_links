module DynamicLinks
  class StrategyFactory
    VALID_SHORTENING_STRATEGIES = [:md5, :sha256, :crc32,
                                   :nano_id, :redis_counter, :mock].freeze

    def self.get_strategy(strategy_name)
      case strategy_name
      when :md5
        ShorteningStrategies::MD5Strategy.new
      when :sha256
        ShorteningStrategies::SHA256Strategy.new
      when :crc32
        ShorteningStrategies::CRC32Strategy.new
      when :nano_id
        ensure_nanoid_available
        ShorteningStrategies::NanoIDStrategy.new
      when :redis_counter
        ensure_redis_available
        ShorteningStrategies::RedisCounterStrategy.new
      when :mock
        ShorteningStrategies::MockStrategy.new
      else
        raise "Unknown strategy: #{strategy_name}"
      end
    end

    def self.ensure_nanoid_available
      begin
        require 'nanoid'
      rescue LoadError
        raise 'Missing dependency: Please add "nanoid" to your Gemfile to use NanoIdStrategy.'
      end
    end

    def self.ensure_redis_available
      begin
        require 'redis'
      rescue LoadError
        raise 'Missing dependency: Please add "redis" to your Gemfile to use RedisCounterStrategy.'
      end

      begin
        require 'connection_pool'
      rescue LoadError
        raise 'Missing dependency: Please add "connection_pool" to your Gemfile to use RedisCounterStrategy.'
      end
    end
  end
end

