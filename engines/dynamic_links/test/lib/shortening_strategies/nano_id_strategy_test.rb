# frozen_string_literal: true

require 'test_helper'
require_relative '../../../lib/dynamic_links/strategy_factory'

module DynamicLinks
  module ShorteningStrategies
    class NanoIDStrategyTest < ActiveSupport::TestCase
      def setup
        @url_shortener = DynamicLinks::StrategyFactory.get_strategy(:nano_id)
      end

      test 'always generates a new shortened URL' do
        assert_equal @url_shortener.always_growing?, true
      end

      test 'shorten returns a string' do
        url = 'https://example.com'
        short_url = @url_shortener.shorten(url)
        assert_kind_of String, short_url
      end

      test 'shorten returns a different short URL for the same long URL' do
        url = 'https://example.com'
        first_result = @url_shortener.shorten(url)
        second_result = @url_shortener.shorten(url)
        assert_not_equal first_result, second_result
      end

      test 'shorten returns a string of at least 5 characters' do
        url = 'https://example.com'
        result = @url_shortener.shorten(url)
        assert result.length >= 5
      end

      test 'shorten returns a string of at least 7 characters' do
        url = 'https://example.com'
        result = @url_shortener.shorten(url, min_length: 7)
        assert result.length >= 7
      end

      test 'shorten handles an empty URL' do
        url = ''
        short_url = @url_shortener.shorten(url)
        assert_not_nil short_url
        assert short_url.length >= DynamicLinks::ShorteningStrategies::NanoIDStrategy::MIN_LENGTH
      end

      test 'shorten handles a very long URL' do
        url = "https://example.com/#{'a' * 500}"
        short_url = @url_shortener.shorten(url)
        assert_kind_of String, short_url
        assert short_url.length >= DynamicLinks::ShorteningStrategies::NanoIDStrategy::MIN_LENGTH
      end

      test 'shorten handles non-URL strings' do
        url = 'this is not a valid URL'
        short_url = @url_shortener.shorten(url)
        assert_kind_of String, short_url
        assert short_url.length >= DynamicLinks::ShorteningStrategies::NanoIDStrategy::MIN_LENGTH
      end

      test 'shorten handles URL with query parameters' do
        url = 'https://example.com?param1=value1&param2=value2'
        short_url = @url_shortener.shorten(url)
        assert_kind_of String, short_url
        assert short_url.length >= DynamicLinks::ShorteningStrategies::NanoIDStrategy::MIN_LENGTH
      end

      test 'shorten handles URL with special characters' do
        url = 'https://example.com/path?query=特殊文字#fragment'
        short_url = @url_shortener.shorten(url)
        assert_kind_of String, short_url
        assert short_url.length >= DynamicLinks::ShorteningStrategies::NanoIDStrategy::MIN_LENGTH
      end

      test '#always_growing? should returns true' do
        assert @url_shortener.always_growing?
      end

      test 'shorten generates URLs with only SMS-safe characters' do
        url = 'https://example.com'
        short_url = @url_shortener.shorten(url)

        # Verify no underscore, hyphen, or other problematic characters
        assert_no_match(/_/, short_url, 'Short URL should not contain underscore')
        assert_no_match(/-/, short_url, 'Short URL should not contain hyphen')
        assert_no_match(/[^0-9A-Za-z]/, short_url, 'Short URL should only contain alphanumeric characters')
      end

      test 'shorten generates 100 URLs all with SMS-safe characters' do
        url = 'https://example.com'
        problematic_chars = []

        100.times do |i|
          short_url = @url_shortener.shorten("#{url}?iteration=#{i}")

          # Check for problematic characters
          problematic_chars << short_url if short_url.match?(/[^0-9A-Za-z]/)
        end

        assert_empty problematic_chars,
                     "Found #{problematic_chars.length} URLs with problematic characters: #{problematic_chars.first(5).join(', ')}"
      end

      test 'shorten uses only Base62 character set (0-9, A-Z, a-z)' do
        url = 'https://example.com'
        short_url = @url_shortener.shorten(url)

        # Verify each character is in the Base62 set
        base62_chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
        short_url.each_char do |char|
          assert_includes base62_chars, char, "Character '#{char}' is not in Base62 character set"
        end
      end

      test 'shorten never generates underscore in short codes' do
        # Generate multiple short URLs to ensure underscore is never used
        short_urls = 50.times.map { @url_shortener.shorten("https://example.com/#{rand(10_000)}") }

        short_urls.each do |short_url|
          refute_includes short_url, '_', "Short URL '#{short_url}' contains underscore"
        end
      end

      test 'shorten generates unique short codes for different URLs' do
        urls = 50.times.map { |i| "https://example.com/page-#{i}" }
        short_urls = urls.map { |url| @url_shortener.shorten(url) }

        # All short URLs should be unique
        assert_equal short_urls.length, short_urls.uniq.length, 'All short URLs should be unique'
      end
    end
  end
end
