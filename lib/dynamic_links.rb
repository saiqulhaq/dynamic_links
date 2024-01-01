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

  @strategy_classes_mutex = Mutex.new

  def self.shorten_url(url)
    @strategy_classes ||= {}
    strategy_key = configuration.shortening_strategy.to_s

    begin
      @strategy_classes_mutex.synchronize do
        @strategy_classes[strategy_key] ||= "DynamicLinks::ShorteningStrategies::#{strategy_key.camelize}Strategy".constantize
      end
      strategy = @strategy_classes[strategy_key].new
    rescue NameError
      raise "Invalid shortening strategy: #{strategy_key}"
    rescue ArgumentError
      raise "#{@strategy_classes[strategy_key]} needs to be initialized with arguments"
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
