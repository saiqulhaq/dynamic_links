require 'test_helper'

module DynamicLinks
  class ShortenedUrlTest < ActiveSupport::TestCase
    self.use_transactional_tests = true

    setup do
      @client = dynamic_links_clients(:one)  # Assuming you have fixtures set up
    end

    test 'should not save shortened url without url' do
      shortened_url = ShortenedUrl.new(client: @client, short_url: 'abc123')
      assert_not shortened_url.save, 'Saved the shortened url without a url'
    end

    test 'should not save shortened url without short_url' do
      shortened_url = ShortenedUrl.new(client: @client, url: 'https://example.com')
      assert_not shortened_url.save, 'Saved the shortened url without a short_url'
    end

    test 'should save valid shortened url' do
      shortened_url = ShortenedUrl.new(client: @client, url: 'https://example.com', short_url: 'abc123')
      assert shortened_url.save, 'Failed to save valid shortened url'
    end

    test 'should not save shortened url with duplicate short_url' do
      ShortenedUrl.create!(client: @client, url: 'https://example.com', short_url: 'abc123')
      duplicate_url = ShortenedUrl.new(client: @client, url: 'https://example.com/another', short_url: 'abc123')
      assert_not duplicate_url.save, 'Saved the shortened url with a duplicate short_url'
    end

    test 'should be associated with a client' do
      shortened_url = ShortenedUrl.create!(url: 'https://example.com', short_url: 'abc123')
      assert_nil shortened_url.client, 'Shortened url has a client when it should not'
    end

    test 'should handle urls without associated client' do
      shortened_url = ShortenedUrl.new(url: 'https://example.com', short_url: 'xyz789')
      assert shortened_url.save, 'Failed to save shortened url without an associated client'
    end

    # Additional tests for expiration logic, custom methods, etc.
  end
end
