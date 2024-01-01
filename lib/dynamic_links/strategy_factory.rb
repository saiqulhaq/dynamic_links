module DynamicLinks
  class StrategyFactory
    def self.get_strategy(strategy_name)
      case strategy_name
      when :md5
        ShorteningStrategies::MD5Strategy.new
      when :sha256
        ShorteningStrategies::SHA256Strategy.new
      when :crc32
        ShorteningStrategies::CRC32Strategy.new
      when :nano_id
        ShorteningStrategies::NanoIdStrategy.new
      when :redis_counter
        ShorteningStrategies::RedisCounterStrategy.new
      when :mock
        ShorteningStrategies::MockStrategy.new
      else
        raise "Unknown strategy: #{strategy_name}"
      end
    end
  end
end

