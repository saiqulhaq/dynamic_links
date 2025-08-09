# frozen_string_literal: true

require 'test_helper'
require 'timecop'

module DynamicLinks
  class RedirectsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @client = dynamic_links_clients(:one)
      @valid_hostname = @client.hostname
      host! @valid_hostname

      @original_fallback_mode = DynamicLinks.configuration.enable_fallback_mode
      @original_firebase_host = DynamicLinks.configuration.firebase_host

      # Clear any existing event subscribers to avoid interference
      @events_captured = []
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        @events_captured << data
      end
    end

    teardown do
      DynamicLinks.configuration.enable_fallback_mode = @original_fallback_mode
      DynamicLinks.configuration.firebase_host = @original_firebase_host
      ActiveSupport::Notifications.unsubscribe(@event_subscriber) if @event_subscriber
      @events_captured = []
    end

    def with_tenant(client, &block)
      # For testing purposes, just yield the block since we're using standard database
      # In production, this would handle tenant-specific database switching
      yield
    end

    test 'redirects to original URL for valid short URL' do
      short_url = dynamic_links_shortened_urls(:one)

      get shortened_url(short_url: short_url.short_url)
      assert_response :found
      assert_redirected_to short_url.url
    end

    test 'responds with not found for non-existent short URL' do
      get shortened_url(short_url: 'nonexistent')
      assert_response :not_found
      assert_match(/not found/i, @response.body)
    end

    test 'responds with not found for expired short URL' do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:expired_url)

        get shortened_url(short_url: short_url.short_url)
        assert_response :not_found
      end
    end

    test 'redirects for valid non-expired short URL' do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:non_expired_url)

        with_tenant(@client) do
          get shortened_url(short_url: short_url.short_url)
          assert_response :found
          assert_redirected_to short_url.url
        end
      end
    end

    test 'responds with not found if host is not in clients' do
      host! 'unknown-host.com'
      short_url = dynamic_links_shortened_urls(:one)

      get shortened_url(short_url: short_url.short_url)
      assert_response :not_found
      assert_equal 'URL not found', @response.body
    end

    test 'validates host header for malicious injection attempts' do
      short_url = dynamic_links_shortened_urls(:one)

      get shortened_url(short_url: short_url.short_url), 
          headers: { 'Host' => "example.com\r\nX-Injected-Header: malicious" }
      assert_response :bad_request
    end

    test 'validates host header for line feed injection attempts' do
      short_url = dynamic_links_shortened_urls(:one)

      get shortened_url(short_url: short_url.short_url), 
          headers: { 'Host' => "example.com\nX-Injected-Header: malicious" }
      assert_response :bad_request
    end

    test 'redirects to Firebase host when short URL not found and fallback mode is enabled' do
      DynamicLinks.configuration.enable_fallback_mode = true
      DynamicLinks.configuration.firebase_host = 'https://k4mu4.app.goo.gl'

      get shortened_url(short_url: 'nonexistent123')
      assert_response :found
      assert_redirected_to 'https://k4mu4.app.goo.gl/nonexistent123'
    end

    test 'responds with not found when fallback mode is enabled but firebase host is blank' do
      DynamicLinks.configuration.enable_fallback_mode = true
      DynamicLinks.configuration.firebase_host = ''

      get shortened_url(short_url: 'nonexistent123')
      assert_response :not_found
    end

    test 'publishes click event on successful redirect' do
      short_url = dynamic_links_shortened_urls(:one)
      initial_event_count = @events_captured.length

      get shortened_url(short_url: short_url.short_url)
      
      assert_response :found
      assert_redirected_to short_url.url
      assert_equal initial_event_count + 1, @events_captured.length
    end

    test 'does not publish click event when URL not found' do
      initial_event_count = @events_captured.length

      get shortened_url(short_url: 'nonexistent')
      
      assert_response :not_found
      assert_equal initial_event_count, @events_captured.length
    end

    test 'does not publish click event when URL is expired' do
      initial_event_count = @events_captured.length
      short_url = dynamic_links_shortened_urls(:expired_url)

      get shortened_url(short_url: short_url.short_url)
      
      assert_response :not_found
      assert_equal initial_event_count, @events_captured.length
    end
  end
end
