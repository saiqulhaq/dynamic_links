require "dynamic_links/version"
require "dynamic_links/engine"
require "dynamic_links/error_classes"
require "dynamic_links/validator"
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

  def self.shorten_url(url, client)
    raise InvalidURIError, 'Invalid URL' unless Validator.valid_url?(url)

    strategy_key = configuration.shortening_strategy

    strategy = begin
      StrategyFactory.get_strategy(strategy_key)
    rescue RuntimeError => e
      # This will catch the 'Unknown strategy' error from the factory
      raise "Invalid shortening strategy: #{strategy_key}. Error: #{e.message}"
    rescue ArgumentError
      raise "#{strategy_key} strategy needs to be initialized with arguments"
    rescue StandardError => e
      raise "Unexpected error while initializing the strategy: #{e.message}"
    end

    if strategy.always_growing?
      short_url = strategy.shorten(url)

      short_url_record = ShortenedUrl.create!(client: client, url: url, short_url: short_url)
      return URI::Generic.build({scheme: client.scheme, host: client.hostname, path: "/#{short_url}"}).to_s
    end

    # If no existing record or always growing, generate new short URL
    short_url = strategy.shorten(url)
    record = ShortenedUrl.find_or_initialize_by(client: client, short_url: short_url)
    if record.new_record?
      record.url = url
      record.save!
      record
    end
    return URI::Generic.build({scheme: client.scheme, host: client.hostname, path: "/#{short_url}"}).to_s
  end

  # mimic Firebase Dynamic Links API
  def self.generate_short_url(original_url, client)
    short_link = shorten_url(original_url, client)

    {
      shortLink: short_link,
      previewLink: "#{short_link}?preview=true",
      warning: []
    }
  end
end
