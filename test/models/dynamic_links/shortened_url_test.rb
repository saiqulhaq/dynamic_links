# == Schema Information
#
# Table name: dynamic_links_shortened_urls
#
#  id         :bigint           not null, primary key
#  client_id  :bigint
#  url        :string(2083)     not null
#  short_url  :string(10)       not null
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dynamic_links_shortened_urls_on_client_id  (client_id)
#  index_dynamic_links_shortened_urls_on_short_url  (short_url) UNIQUE
#
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
      shortened_url = ShortenedUrl.new(client: @client, url: 'https://example.com', short_url: 'abc123ss')
      assert shortened_url.save, 'Failed to save valid shortened url'
    end

    test 'should not save shortened url with duplicate short_url' do
      ShortenedUrl.create!(client: @client, url: 'https://example.com', short_url: 'abc123b')
      duplicate_url = ShortenedUrl.new(client: @client, url: 'https://example.com/another', short_url: 'abc123b')
      assert_not duplicate_url.save, 'Saved the shortened url with a duplicate short_url'
    end

    test 'reference to client is optional' do
      shortened_url = ShortenedUrl.new(url: 'https://example.com', short_url: 'abc123a')
      assert shortened_url.save, 'Failed to save shortened url without an associated client'
    end

    test 'should handle urls without associated client' do
      shortened_url = ShortenedUrl.new(url: 'https://example.com', short_url: 'xyz789')
      assert shortened_url.save, 'Failed to save shortened url without an associated client'
    end
  end
end
