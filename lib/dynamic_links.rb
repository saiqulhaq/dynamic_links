require "dynamic_links/version"
require "dynamic_links/engine"
require "dynamic_links/strategy_factory"
require "dynamic_links/shortening_strategies/base_strategy"
require "dynamic_links/shortening_strategies/sha256_strategy"
require "dynamic_links/shortening_strategies/md5_strategy"
require "dynamic_links/shortening_strategies/crc32_strategy"
require "dynamic_links/shortening_strategies/nano_id_strategy"
require "dynamic_links/shortening_strategies/redis_counter_strategy"
require "dynamic_links/shortening_strategies/mock_strategy"
require "dynamic_links/configuration"

module DynamicLinks
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  def self.shorten_url(url)
    strategy_key = configuration.shortening_strategy

    begin
      strategy = StrategyFactory.get_strategy(strategy_key)
    rescue RuntimeError => e
      # This will catch the 'Unknown strategy' error from the factory
      raise "Invalid shortening strategy: #{strategy_key}. Error: #{e.message}"
    rescue ArgumentError
      raise "#{strategy_key} strategy needs to be initialized with arguments"
    rescue => e
      raise "Unexpected error while initializing the strategy: #{e.message}"
    end

    strategy.shorten(url)
  end

  # mimic Firebase Dynamic Links API
  def self.generate_short_url(original_url)
    short_link = shorten_url(original_url)

    {
      shortLink: short_link,
      previewLink: "#{short_link}?preview=true",
      warning: []
    }
  end
end
