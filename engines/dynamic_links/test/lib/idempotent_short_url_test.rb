# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class IdempotentShortUrlTest < ActiveSupport::TestCase
    def setup
      @client = dynamic_links_clients(:one)
    end

    test 'returns existing short link when input URL points to a known short link of the same client' do
      existing = ShortenedUrl.create!(
        client: @client,
        url: 'https://example.com/target',
        short_url: 'exist01'
      )

      result = DynamicLinks.generate_short_url(
        "#{@client.scheme}://#{@client.hostname}/#{existing.short_url}",
        @client
      )

      assert_equal "#{@client.scheme}://#{@client.hostname}/#{existing.short_url}", result[:shortLink]
    end

    test 'returns existing short link when input URL points to a known short link of a different client' do
      other_client = DynamicLinks::Client.create!(
        name: 'Other', api_key: 'other_key', hostname: 'other.example.com', scheme: 'https'
      )
      existing = ShortenedUrl.create!(
        client: other_client,
        url: 'https://example.com/target',
        short_url: 'other01'
      )

      result = DynamicLinks.generate_short_url(
        "#{other_client.scheme}://#{other_client.hostname}/#{existing.short_url}",
        @client
      )

      assert_equal "#{other_client.scheme}://#{other_client.hostname}/#{existing.short_url}", result[:shortLink]
    end

    test 'creates new short link for normal long URL' do
      result = DynamicLinks.generate_short_url('https://example.com/some-page', @client)
      assert_match(%r{\A#{Regexp.escape(@client.scheme)}://#{Regexp.escape(@client.hostname)}/}, result[:shortLink])
    end

    test 'creates new short link when path has subpath beyond short code' do
      result = DynamicLinks.generate_short_url('https://example.com/path/with/slashes', @client)
      assert_match(%r{\A#{Regexp.escape(@client.scheme)}://#{Regexp.escape(@client.hostname)}/}, result[:shortLink])
    end

    test 'handles https short URL input' do
      https_client = DynamicLinks::Client.create!(
        name: 'HTTPS', api_key: 'https_key', hostname: 'secure.example.com', scheme: 'https'
      )
      existing = ShortenedUrl.create!(
        client: https_client,
        url: 'https://target.example.com/page',
        short_url: 'secure1'
      )

      result = DynamicLinks.generate_short_url(
        "https://#{https_client.hostname}/#{existing.short_url}",
        https_client
      )

      assert_equal "https://#{https_client.hostname}/secure1", result[:shortLink]
    end
  end
end
