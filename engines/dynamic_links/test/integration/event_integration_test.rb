# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class EventIntegrationTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      # Create a fresh client and a shortened URL not relying on fixtures
      @client = DynamicLinks::Client.create!(
        name: 'Integration Client',
        api_key: 'integration_api_key',
        hostname: 'integration-client.test',
        scheme: 'https'
      )

      @shortened_url = DynamicLinks::ShortenedUrl.create!(
        client: @client,
        url: 'https://example.com/integration',
        short_url: 'int123'
      )

      host! @client.hostname

      @events_captured = []
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |_name, _started, _finished, _id, data|
        @events_captured << data
      end
    end

    teardown do
      ActiveSupport::Notifications.unsubscribe(@event_subscriber) if @event_subscriber
    end

    test 'publishes link_clicked event for a newly created client and link' do
      get shortened_url(short_url: @shortened_url.short_url)

      assert_response :found
      assert_redirected_to @shortened_url.url

      # Event captured
      assert_equal 1, @events_captured.length
      payload = @events_captured.first

      # Basic payload checks
      assert_equal @shortened_url, payload[:shortened_url]
      assert_equal @shortened_url.short_url, payload[:short_url]
      assert_equal @shortened_url.url, payload[:original_url]

      # Request metadata presence
      assert_not_nil payload[:request_method]
      assert_not_nil payload[:request_path]
      assert_not_nil payload[:request_query_string]
    end
  end
end
