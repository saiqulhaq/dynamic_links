# frozen_string_literal: true

# Don't require test_helper to avoid loading analytics engines
ENV['RAILS_ENV'] = 'test'
require_relative '../../test/dummy/config/environment'
require 'rails/test_help'

module DynamicLinks
  class EventPublishingIsolatedTest < ActiveSupport::TestCase
    def setup
      @events_captured = []
      # Subscribe only to the specific event we want to test, avoiding any other subscribers
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        @events_captured << {
          name: name,
          started: started,
          finished: finished,
          unique_id: unique_id,
          data: data
        }
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

    test 'Rails instrumentation publishes link_clicked.dynamic_links event with correct structure' do
      event_data = {
        shortened_url: @shortened_url,
        short_url: @shortened_url.short_url,
        original_url: @shortened_url.url,
        user_agent: 'Test Browser',
        referrer: 'https://google.com',
        ip: '127.0.0.1',
        utm_source: 'test',
        utm_medium: 'cpc',
        utm_campaign: 'campaign',
        landing_page: 'https://test.com/abc123'
      }

      # This simulates what the controller does
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

      assert_equal 1, @events_captured.length

      captured_event = @events_captured.first
      assert_equal 'link_clicked.dynamic_links', captured_event[:name]
      assert_instance_of Time, captured_event[:started]
      assert_instance_of Time, captured_event[:finished]
      assert_not_nil captured_event[:unique_id]

      # Verify all expected data is present
      captured_data = captured_event[:data]
      assert_equal @shortened_url, captured_data[:shortened_url]
      assert_equal 'abc123', captured_data[:short_url]
      assert_equal 'https://example.com/target', captured_data[:original_url]
      assert_equal 'Test Browser', captured_data[:user_agent]
      assert_equal 'https://google.com', captured_data[:referrer]
      assert_equal '127.0.0.1', captured_data[:ip]
      assert_equal 'test', captured_data[:utm_source]
      assert_equal 'cpc', captured_data[:utm_medium]
      assert_equal 'campaign', captured_data[:utm_campaign]
      assert_equal 'https://test.com/abc123', captured_data[:landing_page]
    end

    test 'event publishing works with minimal data' do
      minimal_event_data = {
        shortened_url: @shortened_url,
        short_url: @shortened_url.short_url,
        original_url: @shortened_url.url
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', minimal_event_data)

      assert_equal 1, @events_captured.length
      captured_data = @events_captured.first[:data]

      assert_equal @shortened_url, captured_data[:shortened_url]
      assert_equal 'abc123', captured_data[:short_url]
      assert_equal 'https://example.com/target', captured_data[:original_url]

      # Other fields should be accessible even if nil
      assert captured_data.key?(:user_agent) == false || captured_data[:user_agent].nil?
    end

    test 'event publishing handles nil and empty values' do
      event_data_with_nils = {
        shortened_url: @shortened_url,
        short_url: @shortened_url.short_url,
        original_url: @shortened_url.url,
        user_agent: nil,
        referrer: '',
        ip: nil,
        utm_source: nil,
        utm_medium: '',
        utm_campaign: nil,
        landing_page: nil
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data_with_nils)

      assert_equal 1, @events_captured.length
      captured_data = @events_captured.first[:data]

      # Should not raise any errors
      assert_equal @shortened_url, captured_data[:shortened_url]
      assert_nil captured_data[:user_agent]
      assert_equal '', captured_data[:referrer]
      assert_nil captured_data[:ip]
      assert_nil captured_data[:utm_source]
      assert_equal '', captured_data[:utm_medium]
      assert_nil captured_data[:utm_campaign]
      assert_nil captured_data[:landing_page]
    end

    test 'event namespace filtering works correctly' do
      # Subscribe to a different namespace
      other_events = []
      other_subscriber = ActiveSupport::Notifications.subscribe('other.event') do |name, started, finished, unique_id, data|
        other_events << data
      end

      begin
        # Publish both events
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'dynamic_links' })
        ActiveSupport::Notifications.instrument('other.event', { test: 'other' })

        # Our subscriber should only see the dynamic_links event
        assert_equal 1, @events_captured.length
        assert_equal 'dynamic_links', @events_captured.first[:data][:test]

        # Other subscriber should only see the other event
        assert_equal 1, other_events.length
        assert_equal 'other', other_events.first[:test]
      ensure
        ActiveSupport::Notifications.unsubscribe(other_subscriber)
      end
    end

    test 'multiple subscribers can listen to same event without interference' do
      second_events = []
      second_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        second_events << { name: name, data: data }
      end

      begin
        event_data = { shortened_url: @shortened_url, test_id: 'multi_subscriber' }

        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

        # Both subscribers should receive the event
        assert_equal 1, @events_captured.length
        assert_equal 1, second_events.length

        # Data should be the same in both
        assert_equal event_data, @events_captured.first[:data]
        assert_equal event_data, second_events.first[:data]
        assert_equal 'multi_subscriber', @events_captured.first[:data][:test_id]
        assert_equal 'multi_subscriber', second_events.first[:data][:test_id]
      ensure
        ActiveSupport::Notifications.unsubscribe(second_subscriber)
      end
    end

    test 'event timing information is captured' do
      start_time = Time.current

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'timing' }) do
        sleep 0.001 # Small delay to ensure measurable duration
      end

      end_time = Time.current

      assert_equal 1, @events_captured.length
      captured_event = @events_captured.first

      assert captured_event[:started] >= start_time
      assert captured_event[:finished] <= end_time
      assert captured_event[:finished] >= captured_event[:started]

      # Duration should be positive (even if very small)
      duration = captured_event[:finished] - captured_event[:started]
      assert duration >= 0
    end

    test 'unique_id is generated for each event' do
      # Use two separate threads to ensure unique IDs
      thread1 = Thread.new do
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'first' })
      end

      thread2 = Thread.new do
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'second' })
      end

      thread1.join
      thread2.join

      assert_equal 2, @events_captured.length

      first_id = @events_captured.first[:unique_id]
      second_id = @events_captured.last[:unique_id]

      assert_not_nil first_id
      assert_not_nil second_id
      assert_not_equal first_id, second_id
    end

    test 'controller publish_click_event method behavior simulation' do
      # Simulate the exact logic from the controller method
      link = @shortened_url

      # Test early return condition
      assert_not link.blank?, 'Link should not be blank'

      # Simulate building event data structure like the controller does
      mock_request = Struct.new(:user_agent, :referrer, :remote_ip, :original_url).new(
        'Mock Browser 1.0',
        'https://referring-site.com',
        '192.168.1.100',
        'https://test.com/abc123'
      )

      mock_params = { utm_source: 'google', utm_medium: 'organic', utm_campaign: 'summer2024' }

      # Build event data exactly as controller would
      event_data = {
        shortened_url: link,
        short_url: link.short_url,
        original_url: link.url,
        user_agent: mock_request.user_agent,
        referrer: mock_request.referrer,
        ip: mock_request.remote_ip,
        utm_source: mock_params[:utm_source],
        utm_medium: mock_params[:utm_medium],
        utm_campaign: mock_params[:utm_campaign],
        landing_page: mock_request.original_url,
        request: mock_request
      }

      # Publish event as controller would
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

      # Verify event was published with correct data
      assert_equal 1, @events_captured.length
      captured_data = @events_captured.first[:data]

      assert_equal link, captured_data[:shortened_url]
      assert_equal 'abc123', captured_data[:short_url]
      assert_equal 'https://example.com/target', captured_data[:original_url]
      assert_equal 'Mock Browser 1.0', captured_data[:user_agent]
      assert_equal 'https://referring-site.com', captured_data[:referrer]
      assert_equal '192.168.1.100', captured_data[:ip]
      assert_equal 'google', captured_data[:utm_source]
      assert_equal 'organic', captured_data[:utm_medium]
      assert_equal 'summer2024', captured_data[:utm_campaign]
      assert_equal 'https://test.com/abc123', captured_data[:landing_page]
      assert_equal mock_request, captured_data[:request]
    end
  end
end
