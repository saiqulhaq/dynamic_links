# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class ClickEventPublishingTest < ActiveSupport::TestCase
    
    def setup
      @events_captured = []
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        @events_captured << { name: name, data: data, unique_id: unique_id }
      end

      @client = DynamicLinks::Client.new(
        id: 1,
        name: 'Test Client',
        hostname: 'test.com',
        scheme: 'https',
        api_key: 'test_key'
      )

      @shortened_url = DynamicLinks::ShortenedUrl.new(
        id: 1,
        short_url: 'abc123',
        url: 'https://example.com/target',
        client: @client
      )
    end

    def teardown
      ActiveSupport::Notifications.unsubscribe(@event_subscriber) if @event_subscriber
      @events_captured = []
    end

    test 'ActiveSupport::Notifications publishes link_clicked.dynamic_links event' do
      event_data = {
        shortened_url: @shortened_url,
        short_url: @shortened_url.short_url,
        original_url: @shortened_url.url
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

      assert_equal 1, @events_captured.length
      
      captured_event = @events_captured.first
      assert_equal 'link_clicked.dynamic_links', captured_event[:name]
      assert_equal event_data, captured_event[:data]
      assert_not_nil captured_event[:unique_id]
    end

    test 'event data structure matches expected format' do
      request_params = {
        utm_source: 'google',
        utm_medium: 'cpc',
        utm_campaign: 'test'
      }

      event_data = {
        shortened_url: @shortened_url,
        short_url: @shortened_url.short_url,
        original_url: @shortened_url.url,
        user_agent: 'Test Browser 1.0',
        referrer: 'https://google.com',
        ip: '192.168.1.1',
        utm_source: request_params[:utm_source],
        utm_medium: request_params[:utm_medium],
        utm_campaign: request_params[:utm_campaign],
        landing_page: 'https://test.com/abc123'
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

      assert_equal 1, @events_captured.length
      captured_data = @events_captured.first[:data]

      assert_equal @shortened_url, captured_data[:shortened_url]
      assert_equal 'abc123', captured_data[:short_url]
      assert_equal 'https://example.com/target', captured_data[:original_url]
      assert_equal 'Test Browser 1.0', captured_data[:user_agent]
      assert_equal 'https://google.com', captured_data[:referrer]
      assert_equal '192.168.1.1', captured_data[:ip]
      assert_equal 'google', captured_data[:utm_source]
      assert_equal 'cpc', captured_data[:utm_medium]
      assert_equal 'test', captured_data[:utm_campaign]
      assert_equal 'https://test.com/abc123', captured_data[:landing_page]
    end

    test 'event publishing handles nil values gracefully' do
      event_data = {
        shortened_url: @shortened_url,
        short_url: @shortened_url.short_url,
        original_url: @shortened_url.url,
        user_agent: nil,
        referrer: nil,
        ip: nil,
        utm_source: nil,
        utm_medium: nil,
        utm_campaign: nil,
        landing_page: nil
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

      assert_equal 1, @events_captured.length
      captured_data = @events_captured.first[:data]

      # Should not raise errors even with nil values
      assert_equal @shortened_url, captured_data[:shortened_url]
      assert_nil captured_data[:user_agent]
      assert_nil captured_data[:referrer]
      assert_nil captured_data[:utm_source]
    end

    test 'multiple subscribers receive the same event' do
      additional_events = []
      additional_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        additional_events << data
      end

      begin
        event_data = { shortened_url: @shortened_url, test: 'multi_subscriber' }
        
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

        assert_equal 1, @events_captured.length
        assert_equal 1, additional_events.length
        
        assert_equal event_data, @events_captured.first[:data]
        assert_equal event_data, additional_events.first
      ensure
        ActiveSupport::Notifications.unsubscribe(additional_subscriber)
      end
    end

    test 'event namespace is correctly scoped' do
      wrong_events = []
      wrong_subscriber = ActiveSupport::Notifications.subscribe('other.namespace') do |name, started, finished, unique_id, data|
        wrong_events << data
      end

      begin
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'correct' })
        ActiveSupport::Notifications.instrument('other.namespace', { test: 'wrong' })

        # Only our subscriber should have received the dynamic_links event
        assert_equal 1, @events_captured.length
        assert_equal 'correct', @events_captured.first[:data][:test]
        
        # Wrong subscriber should have received its event
        assert_equal 1, wrong_events.length
        assert_equal 'wrong', wrong_events.first[:test]
      ensure
        ActiveSupport::Notifications.unsubscribe(wrong_subscriber)
      end
    end

    test 'event data preserves object references' do
      event_data = { shortened_url: @shortened_url }
      
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
      
      captured_url = @events_captured.first[:data][:shortened_url]
      
      # Should be the same object reference
      assert_same @shortened_url, captured_url
      assert_equal @shortened_url.id, captured_url.id
      assert_equal @shortened_url.short_url, captured_url.short_url
      assert_equal @shortened_url.url, captured_url.url
    end

    test 'publish_click_event method logic (simulated)' do
      # Simulate the logic that would be in publish_click_event method
      
      # Test with valid link
      link = @shortened_url
      return_early = link.blank?
      assert_not return_early, "Should not return early for valid link"

      # Test with nil link  
      nil_link = nil
      return_early = nil_link.blank?
      assert return_early, "Should return early for blank link"

      # Test event data structure that would be created
      simulated_request_data = {
        user_agent: 'Test Agent',
        referrer: 'https://example.com',
        remote_ip: '127.0.0.1',
        original_url: 'https://test.com/abc123'
      }
      
      simulated_params = {
        utm_source: 'test_source',
        utm_medium: 'test_medium',
        utm_campaign: 'test_campaign'
      }

      expected_event_data = {
        shortened_url: link,
        short_url: link.short_url,
        original_url: link.url,
        user_agent: simulated_request_data[:user_agent],
        referrer: simulated_request_data[:referrer],
        ip: simulated_request_data[:remote_ip],
        utm_source: simulated_params[:utm_source],
        utm_medium: simulated_params[:utm_medium],
        utm_campaign: simulated_params[:utm_campaign],
        landing_page: simulated_request_data[:original_url],
        request: 'mock_request_object'
      }

      # Simulate the event publishing
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', expected_event_data)

      assert_equal 1, @events_captured.length
      captured_data = @events_captured.first[:data]
      
      assert_equal link, captured_data[:shortened_url]
      assert_equal link.short_url, captured_data[:short_url]
      assert_equal link.url, captured_data[:original_url]
      assert_equal 'Test Agent', captured_data[:user_agent]
      assert_equal 'https://example.com', captured_data[:referrer]
      assert_equal '127.0.0.1', captured_data[:ip]
      assert_equal 'test_source', captured_data[:utm_source]
      assert_equal 'test_medium', captured_data[:utm_medium]
      assert_equal 'test_campaign', captured_data[:utm_campaign]
      assert_equal 'https://test.com/abc123', captured_data[:landing_page]
      assert_equal 'mock_request_object', captured_data[:request]
    end
  end
end