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

require "dynamic_links/version"
require "dynamic_links/engine"
require "dynamic_links/error_classes"
require "dynamic_links/configuration"
require "dynamic_links/redis_config"
require "dynamic_links/validator"
require "dynamic_links/strategy_factory"
require 'dynamic_links/cache_store/base_cache_store'
require 'dynamic_links/cache_store/redis_cache_store'
require 'dynamic_links/cache_store/memcached_cache_store'
require "dynamic_links/shortening_strategies/base_strategy"
require "dynamic_links/shortening_strategies/sha256_strategy"
require "dynamic_links/shortening_strategies/md5_strategy"
require "dynamic_links/shortening_strategies/crc32_strategy"
require "dynamic_links/shortening_strategies/nano_id_strategy"
require "dynamic_links/shortening_strategies/redis_counter_strategy"
require "dynamic_links/shortening_strategies/mock_strategy"

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

    strategy_key = DynamicLinks.configuration.shortening_strategy
    strategy = StrategyFactory.get_strategy(strategy_key)
    short_url = strategy.shorten(url)

    if async
      lock_key = "lock:shorten_url:#{short_url}"
      cache_store = DynamicLinks.configuration.cache_store

      if cache_store.read(lock_key)
        # Return the short url if it is already in the cache
        return URI::Generic.build({scheme: client.scheme, host: client.hostname, path: "/#{short_url}"}).to_s
      end

      # Set a lock and store data in cache
      cache_store.write(lock_key, 'locked', { expires_in: 10.minutes })
      cache_key = "shorten_url:#{client.id}:#{short_url}"
      cache_store.write(cache_key, { url: url, short_url: short_url })

      ShortenUrlJob.perform_later(client, url, short_url, lock_key)
      URI::Generic.build({scheme: client.scheme, host: client.hostname, path: "/#{short_url}"}).to_s
    else
      # Synchronous processing
      process_url_synchronously(url, short_url, client, strategy)
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

  private

  # TODO Handle issue when failed to save record
  def self.process_url_synchronously(url, short_url, client, strategy)
    if strategy.always_growing?
      ShortenedUrl.create!(client: client, url: url, short_url: short_url)
    else
      record = ShortenedUrl.find_or_initialize_by(client: client, short_url: short_url)
      record.url = url if record.new_record?
      record.save!
    end
    URI::Generic.build({scheme: client.scheme, host: client.hostname, path: "/#{short_url}"}).to_s
  end
end
