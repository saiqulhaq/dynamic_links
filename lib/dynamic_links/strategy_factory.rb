module DynamicLinks
  class StrategyFactory
    def self.get_strategy(strategy_name)
      case strategy_name
      when :md5
        ShorteningStrategies::MD5Strategy.new
      when :sha256
        ShorteningStrategies::SHA256Strategy.new
      # Other strategies...
      else
        raise "Unknown strategy: #{strategy_name}"
      end
    end
  end
end

