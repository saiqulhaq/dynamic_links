# frozen_string_literal: true

# @author Saiqul Haq <saiqulhaq@gmail.com>

if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'

  SimpleCov.start do
    load_profile 'test_frameworks'

    add_filter %r{^/config/}
    add_filter %r{^/db/}

    add_group 'Controllers', 'app/controllers'
    add_group 'Channels', 'app/channels'
    add_group 'Models', 'app/models'
    add_group 'Mailers', 'app/mailers'
    add_group 'Helpers', 'app/helpers'
    add_group 'Jobs', %w[app/jobs app/workers]
    add_group 'DynamicLinks', 'lib/'
  end
end

require 'dynamic_links/version'
require 'dynamic_links/engine'
require 'dynamic_links/logger'
require 'dynamic_links/error_classes'
require 'dynamic_links/redis_config'
require 'dynamic_links/configuration'
require 'dynamic_links/validator'
require 'dynamic_links/strategy_factory'
require 'dynamic_links/shortening_strategies/base_strategy'
require 'dynamic_links/shortening_strategies/sha256_strategy'
require 'dynamic_links/shortening_strategies/md5_strategy'
require 'dynamic_links/shortening_strategies/crc32_strategy'
require 'dynamic_links/shortening_strategies/nano_id_strategy'
require 'dynamic_links/shortening_strategies/redis_counter_strategy'
require 'dynamic_links/shortening_strategies/mock_strategy'
require 'dynamic_links/async/locker'
require 'dynamic_links/shortener'

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

  def self.shorten_url(url, client, async: DynamicLinks.configuration.async_processing, expires_at: nil)
    raise InvalidURIError, 'Invalid URL' unless Validator.valid_url?(url)

    shortener = Shortener.new
    if async
      shortener.shorten_async(client, url, expires_at: expires_at)
    else
      shortener.shorten(client, url, expires_at: expires_at)
    end
  end

  # mimic Firebase Dynamic Links API
  def self.generate_short_url(original_url, client, expires_at: nil)
    short_link = idempotent_short_link(original_url, client, expires_at: expires_at)

    {
      shortLink: short_link,
      previewLink: "#{short_link}?preview=true",
      warning: []
    }
  end

  # If `original_url` is itself a short link of `client` (or any client),
  # return the existing short link instead of creating a new one.
  # This prevents accidental chains like A -> short(B) -> short(short(B)).
  def self.idempotent_short_link(original_url, client, expires_at: nil)
    existing = find_existing_short_link_for_url(original_url)
    return existing if existing

    shorten_url(original_url, client, expires_at: expires_at)
  end

  # Returns the full short link string (scheme://host/short_code) if `url`
  # matches a known short link of any client, otherwise nil.
  def self.find_existing_short_link_for_url(url)
    return nil if url.blank?

    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    return nil if uri.host.blank?

    short_code = uri.path.to_s.sub(%r{\A/}, '')
    return nil if short_code.blank?
    return nil if short_code.include?('/')

    record = DynamicLinks::ShortenedUrl.find_by(short_url: short_code)
    return nil unless record

    owner = record.client
    "#{owner.scheme}://#{owner.hostname}/#{record.short_url}"
  rescue URI::InvalidURIError
    nil
  end

  def self.resolve_short_url(short_link)
    DynamicLinks::ShortenedUrl.find_by(short_url: short_link)&.url
  end

  def self.find_short_link(long_url, client)
    short_link = DynamicLinks::ShortenedUrl.find_by(url: long_url, client_id: client.id)
    return unless short_link
    # Treat an expired short link as not-found so `find_or_create` mints
    # a fresh short code for the same long URL once the previous one
    # has passed its `expires_at`. Lets shortlinks be "reused" after
    # the default 3-month lifetime.
    return if short_link.expired?

    {
      short_url: "#{client.scheme}://#{client.hostname}/#{short_link.short_url}",
      full_url: long_url
    }
  end
end
