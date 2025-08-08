# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class InstrumentationTest < ActiveSupport::TestCase
    setup do
      @events_captured = []
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        @events_captured << { 
          name: name, 
          started: started, 
          finished: finished, 
          unique_id: unique_id, 
          data: data 
        }
      end
    end

    teardown do
      ActiveSupport::Notifications.unsubscribe(@event_subscriber) if @event_subscriber
      @events_captured = []
    end

    test 'ActiveSupport::Notifications.instrument publishes event with correct namespace' do
      test_data = { test_key: 'test_value' }
      
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', test_data)
      
      assert_equal 1, @events_captured.length
      
      event = @events_captured.first
      assert_equal 'link_clicked.dynamic_links', event[:name]
      assert_equal test_data, event[:data]
      assert_instance_of Time, event[:started]
      assert_instance_of Time, event[:finished]
      assert_not_nil event[:unique_id]
    end

    test 'instrumentation works with complex data structures' do
      client = dynamic_links_clients(:one)
      shortened_url = dynamic_links_shortened_urls(:one)
      
      complex_data = {
        shortened_url: shortened_url,
        client: client,
        metadata: {
          utm_params: {
            source: 'google',
            medium: 'cpc'
          },
          browser_info: {
            user_agent: 'Mozilla/5.0',
            ip: '127.0.0.1'
          }
        }
      }
      
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', complex_data)
      
      assert_equal 1, @events_captured.length
      
      event_data = @events_captured.first[:data]
      assert_equal shortened_url, event_data[:shortened_url]
      assert_equal client, event_data[:client]
      assert_equal 'google', event_data[:metadata][:utm_params][:source]
      assert_equal 'Mozilla/5.0', event_data[:metadata][:browser_info][:user_agent]
    end

    test 'multiple subscribers can listen to the same event' do
      additional_events_captured = []
      additional_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        additional_events_captured << data
      end

      begin
        test_data = { message: 'multi-subscriber test' }
        
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', test_data)
        
        assert_equal 1, @events_captured.length
        assert_equal 1, additional_events_captured.length
        
        assert_equal test_data, @events_captured.first[:data]
        assert_equal test_data, additional_events_captured.first
      ensure
        ActiveSupport::Notifications.unsubscribe(additional_subscriber)
      end
    end

    test 'instrumentation works with nil data' do
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', nil)
      
      assert_equal 1, @events_captured.length
      assert_nil @events_captured.first[:data]
    end

    test 'instrumentation timing is captured correctly' do
      start_time = Time.current
      
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', {}) do
        sleep 0.001 # Small delay to ensure timing difference
      end
      
      end_time = Time.current
      
      assert_equal 1, @events_captured.length
      event = @events_captured.first
      
      assert event[:started] >= start_time
      assert event[:finished] <= end_time
      assert event[:finished] >= event[:started]
    end

    test 'event namespace filtering works correctly' do
      wrong_namespace_events = []
      wrong_subscriber = ActiveSupport::Notifications.subscribe('different.namespace') do |name, started, finished, unique_id, data|
        wrong_namespace_events << data
      end

      begin
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: true })
        ActiveSupport::Notifications.instrument('different.namespace', { test: true })
        
        # Our subscriber should only capture the dynamic_links event
        assert_equal 1, @events_captured.length
        assert_equal 'link_clicked.dynamic_links', @events_captured.first[:name]
        
        # Wrong namespace subscriber should only capture its event
        assert_equal 1, wrong_namespace_events.length
      ensure
        ActiveSupport::Notifications.unsubscribe(wrong_subscriber)
      end
    end

    test 'instrumentation continues to work after subscriber errors' do
      error_prone_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        raise StandardError, 'Subscriber error'
      end

      begin
        # The error from the subscriber should be raised
        assert_raises(StandardError, 'Subscriber error') do
          ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'error_handling' })
        end
        
        # Our main subscriber may have captured the event before the error occurred
        # The exact count depends on subscriber execution order
        initial_count = @events_captured.length
      ensure
        ActiveSupport::Notifications.unsubscribe(error_prone_subscriber)
      end
      
      # After removing the error-prone subscriber, instrumentation should work normally
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'after_error' })
      
      # Now our subscriber should work normally (we should have one more event)
      assert_equal initial_count + 1, @events_captured.length
      assert_equal 'after_error', @events_captured.last[:data][:test]
    end
  end
end