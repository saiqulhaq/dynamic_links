module DynamicLinks
  class StrategyFactory
    def self.get_strategy(strategy_name)
      case strategy_name
      when :md5
        ShorteningStrategies::Md5Strategy.new
      when :base62
        ShorteningStrategies::Base62Strategy.new
      # Other strategies...
      else
        raise "Unknown strategy: #{strategy_name}"
      end
    end
  end
end

