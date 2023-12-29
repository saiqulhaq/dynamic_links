require "dynamic_links/version"
require "dynamic_links/engine"
require "dynamic_links/strategy_factory"
require "dynamic_links/shortening_strategies/base_strategy"
require "dynamic_links/shortening_strategies/sha256_strategy"
require "dynamic_links/shortening_strategies/md5_strategy"
require "dynamic_links/shortening_strategies/crc32_strategy"
require "dynamic_links/shortening_strategies/nano_id_strategy"

module DynamicLinks; end

strategy = DynamicLinks::StrategyFactory.get_strategy(:md5)
short_url = strategy.shorten("https://example.com")

module DynamicLinks
  class UrlShortener
    MIN_LENGTH = 5

    def valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError
      false
    end
  end
end
