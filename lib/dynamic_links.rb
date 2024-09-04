# @author Saiqul Haq <saiqulhaq@gmail.com>

if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'

  SimpleCov.start do
    load_profile "test_frameworks"

    add_filter %r{^/config/}
    add_filter %r{^/db/}

    add_group "Controllers", "app/controllers"
    add_group "Channels", "app/channels"
    add_group "Models", "app/models"
    add_group "Mailers", "app/mailers"
    add_group "Helpers", "app/helpers"
    add_group "Jobs", %w[app/jobs app/workers]
    add_group "DynamicLinks", "lib/"
  end
end

begin
  require "ahoy_matey"
rescue LoadError
  # it's okay if ahoy_matey is not available
end

require "dynamic_links/version"
require "dynamic_links/engine"
require "dynamic_links/logger"
require "dynamic_links/error_classes"
require "dynamic_links/redis_config"
require "dynamic_links/configuration"
require "dynamic_links/validator"
require "dynamic_links/strategy_factory"
require "dynamic_links/shortening_strategies/base_strategy"
require "dynamic_links/shortening_strategies/sha256_strategy"
require "dynamic_links/shortening_strategies/md5_strategy"
require "dynamic_links/shortening_strategies/crc32_strategy"
require "dynamic_links/shortening_strategies/nano_id_strategy"
require "dynamic_links/shortening_strategies/redis_counter_strategy"
require "dynamic_links/shortening_strategies/mock_strategy"
require "dynamic_links/async/locker"
require "dynamic_links/shortener"

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

  def self.shorten_url(url, client, async: DynamicLinks.configuration.async_processing)
    raise InvalidURIError, 'Invalid URL' unless Validator.valid_url?(url)

    shortener = Shortener.new
    if async
      shortener.shorten_async(client, url)
    else
      shortener.shorten(client, url)
    end
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

  def self.resolve_short_url(short_link)
    DynamicLinks::ShortenedUrl.find_by(short_url: short_link)&.url
  end

  def self.find_short_link(long_url, client)
    short_link = DynamicLinks::ShortenedUrl.find_by(url: long_url, client_id: client.id)
    if short_link
      {
        short_url: "#{client.scheme}://#{client.hostname}/#{short_link.short_url}",
        full_url: long_url
      }
    else
      nil
    end
  end
end
