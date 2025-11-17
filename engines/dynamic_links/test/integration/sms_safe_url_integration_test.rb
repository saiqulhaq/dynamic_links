# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  # Integration test to verify SMS-safe URL generation end-to-end
  class SmsSafeUrlIntegrationTest < ActiveSupport::TestCase
    def setup
      @client = dynamic_links_clients(:one)
      @original_strategy = DynamicLinks.configuration.shortening_strategy
    end

    def teardown
      # Clean up any shortened URLs created during tests (except fixtures)
      DynamicLinks::ShortenedUrl.where(client: @client).where.not(short_url: %w[abc123 ghi789 jkl012]).destroy_all
      # Restore original configuration
      DynamicLinks.configuration.shortening_strategy = @original_strategy
    end

    test 'generates SMS-safe URLs with nano_id strategy' do
      DynamicLinks.configuration.shortening_strategy = :nano_id

      # Generate multiple URLs
      short_urls = 50.times.map do |i|
        result = DynamicLinks.shorten_url("https://example.com/nano/page-#{i}", @client)
        # Extract just the short code from the full URL
        result.split('/').last
      end

      # Verify all generated URLs are SMS-safe
      short_urls.each do |short_code|
        assert_match(/\A[0-9A-Za-z]+\z/, short_code,
                    "Short code '#{short_code}' contains non-SMS-safe characters")
        assert_no_match(/_/, short_code, "Short code '#{short_code}' contains underscore")
        assert_no_match(/-/, short_code, "Short code '#{short_code}' contains hyphen")
      end

      # Verify all URLs are unique
      assert_equal short_urls.length, short_urls.uniq.length,
                  'All short codes should be unique'
    end

    test 'generates SMS-safe URLs with md5 strategy' do
      DynamicLinks.configuration.shortening_strategy = :md5

      short_url = DynamicLinks.shorten_url("https://example.com/md5/test", @client)
      short_code = short_url.split('/').last

      assert_match(/\A[0-9A-Za-z]+\z/, short_code,
                  "MD5 short code '#{short_code}' should be SMS-safe")
    end

    test 'generates SMS-safe URLs with sha256 strategy' do
      DynamicLinks.configuration.shortening_strategy = :sha256

      short_url = DynamicLinks.shorten_url("https://example.com/sha256/test", @client)
      short_code = short_url.split('/').last

      assert_match(/\A[0-9A-Za-z]+\z/, short_code,
                  "SHA256 short code '#{short_code}' should be SMS-safe")
    end

    test 'generates SMS-safe URLs with crc32 strategy' do
      DynamicLinks.configuration.shortening_strategy = :crc32

      short_url = DynamicLinks.shorten_url("https://example.com/crc32/test", @client)
      short_code = short_url.split('/').last

      assert_match(/\A[0-9A-Za-z]+\z/, short_code,
                  "CRC32 short code '#{short_code}' should be SMS-safe")
    end

    test 'prevents creation of URLs with underscores' do
      # Attempt to directly create a URL with underscore
      url = ShortenedUrl.new(
        client: @client,
        url: 'https://example.com/underscore_test',
        short_url: 'abc_123'
      )

      assert_not url.valid?, 'ShortenedUrl with underscore should not be valid'
      assert_includes url.errors[:short_url],
                     'must contain only alphanumeric characters (0-9, A-Z, a-z) for SMS compatibility'
    end

    test 'prevents creation of URLs with hyphens' do
      # Attempt to directly create a URL with hyphen
      url = ShortenedUrl.new(
        client: @client,
        url: 'https://example.com/hyphen_test',
        short_url: 'abc-123'
      )

      assert_not url.valid?, 'ShortenedUrl with hyphen should not be valid'
      assert_includes url.errors[:short_url],
                     'must contain only alphanumeric characters (0-9, A-Z, a-z) for SMS compatibility'
    end

    test 'allows creation of URLs with only alphanumeric characters' do
      url = ShortenedUrl.new(
        client: @client,
        url: 'https://example.com/alphanum_test',
        short_url: 'aB3xZ9'
      )

      assert url.valid?, "ShortenedUrl with alphanumeric characters should be valid. Errors: #{url.errors.full_messages}"
      assert url.save, 'Should be able to save SMS-safe short URL'
    end

    test 'generates 100 SMS-safe URLs without any problematic characters' do
      DynamicLinks.configuration.shortening_strategy = :nano_id

      problematic_urls = []

      100.times do |i|
        short_url = DynamicLinks.shorten_url("https://example.com/bulk/test-#{i}", @client)
        short_code = short_url.split('/').last

        # Check if short code contains any non-alphanumeric characters
        if short_code.match?(/[^0-9A-Za-z]/)
          problematic_urls << { index: i, code: short_code }
        end
      end

      assert_empty problematic_urls,
                  "Found #{problematic_urls.length} URLs with problematic characters: #{problematic_urls.first(5).inspect}"
    end
  end
end
