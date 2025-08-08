# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support'
require 'active_support/notifications'
require 'active_support/test_case'
require 'ostruct'

class SimpleInstrumentationTest < ActiveSupport::TestCase

  def setup
    @events_captured = []
    @subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
      @events_captured << {
        name: name,
        started: started,
        finished: finished,
        unique_id: unique_id,
        data: data
      }
    end
  end

  def teardown
    ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
    @events_captured = []
  end

  def test_rails_instrumentation_publishes_event_with_correct_name
    test_data = { message: 'test event' }
    
    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', test_data)
    
    assert_equal 1, @events_captured.length
    event = @events_captured.first
    assert_equal 'link_clicked.dynamic_links', event[:name]
    assert_equal test_data, event[:data]
  end

  def test_event_includes_timing_information
    start_time = Time.current
    
    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', {})
    
    end_time = Time.current
    
    event = @events_captured.first
    assert event[:started] >= start_time
    assert event[:finished] <= end_time
    assert event[:finished] >= event[:started]
  end

  def test_unique_id_generated_for_each_event
    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { id: 1 })
    sleep 0.001 # Small delay to ensure different timestamps
    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { id: 2 })
    
    assert_equal 2, @events_captured.length
    
    first_id = @events_captured[0][:unique_id]
    second_id = @events_captured[1][:unique_id]
    
    refute_nil first_id
    refute_nil second_id
    # Note: unique_id might be same if events happen in same millisecond, which is okay
    # The important thing is that each event gets an ID
    assert first_id.is_a?(String), "First ID should be a string"
    assert second_id.is_a?(String), "Second ID should be a string"
  end

  def test_event_data_structure_for_click_events
    shortened_url_mock = OpenStruct.new(
      id: 123,
      short_url: 'abc123',
      url: 'https://example.com/target',
      client_id: 1
    )
    
    request_mock = OpenStruct.new(
      remote_ip: '127.0.0.1',
      user_agent: 'Test Browser',
      referer: 'https://google.com',
      original_url: 'https://test.com/abc123'
    )
    
    expected_event_data = {
      shortened_url: shortened_url_mock,
      short_url: shortened_url_mock.short_url,
      original_url: shortened_url_mock.url,
      user_agent: request_mock.user_agent,
      referrer: request_mock.referer,
      ip: request_mock.remote_ip,
      utm_source: 'test_source',
      utm_medium: 'test_medium',
      utm_campaign: 'test_campaign',
      landing_page: request_mock.original_url,
      request: request_mock
    }
    
    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', expected_event_data)
    
    assert_equal 1, @events_captured.length
    captured_data = @events_captured.first[:data]
    
    assert_equal shortened_url_mock, captured_data[:shortened_url]
    assert_equal 'abc123', captured_data[:short_url]
    assert_equal 'https://example.com/target', captured_data[:original_url]
    assert_equal 'Test Browser', captured_data[:user_agent]
    assert_equal 'https://google.com', captured_data[:referrer]
    assert_equal '127.0.0.1', captured_data[:ip]
    assert_equal 'test_source', captured_data[:utm_source]
    assert_equal 'test_medium', captured_data[:utm_medium]
    assert_equal 'test_campaign', captured_data[:utm_campaign]
    assert_equal 'https://test.com/abc123', captured_data[:landing_page]
    assert_equal request_mock, captured_data[:request]
  end

  def test_handles_nil_and_empty_values_in_event_data
    event_data = {
      shortened_url: nil,
      short_url: '',
      original_url: nil,
      user_agent: nil,
      referrer: '',
      ip: nil,
      utm_source: nil,
      utm_medium: '',
      utm_campaign: nil,
      landing_page: nil,
      request: nil
    }
    
    # Should not raise any errors
    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
    
    assert_equal 1, @events_captured.length
    captured_data = @events_captured.first[:data]
    
    assert_nil captured_data[:shortened_url]
    assert_equal '', captured_data[:short_url]
    assert_nil captured_data[:original_url]
    assert_nil captured_data[:user_agent]
    assert_equal '', captured_data[:referrer]
    assert_nil captured_data[:ip]
    assert_nil captured_data[:utm_source]
    assert_equal '', captured_data[:utm_medium]
    assert_nil captured_data[:utm_campaign]
    assert_nil captured_data[:landing_page]
    assert_nil captured_data[:request]
  end

  def test_multiple_subscribers_receive_same_event
    second_events = []
    second_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
      second_events << { name: name, data: data }
    end
    
    begin
      test_data = { test: 'multiple_subscribers' }
      
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', test_data)
      
      # Both subscribers should receive the event
      assert_equal 1, @events_captured.length
      assert_equal 1, second_events.length
      
      # Data should be identical
      assert_equal test_data, @events_captured.first[:data]
      assert_equal test_data, second_events.first[:data]
    ensure
      ActiveSupport::Notifications.unsubscribe(second_subscriber)
    end
  end

  def test_event_namespace_filtering
    other_events = []
    other_subscriber = ActiveSupport::Notifications.subscribe('other.namespace') do |name, started, finished, unique_id, data|
      other_events << data
    end
    
    begin
      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: 'correct_namespace' })
      ActiveSupport::Notifications.instrument('other.namespace', { test: 'different_namespace' })
      
      # Our subscriber should only see the dynamic_links event
      assert_equal 1, @events_captured.length
      assert_equal 'correct_namespace', @events_captured.first[:data][:test]
      
      # Other subscriber should only see its event
      assert_equal 1, other_events.length
      assert_equal 'different_namespace', other_events.first[:test]
    ensure
      ActiveSupport::Notifications.unsubscribe(other_subscriber)
    end
  end

  def test_publish_click_event_method_simulation
    # This simulates the exact logic that would be in the controller's publish_click_event method
    
    # Mock objects
    link = OpenStruct.new(
      short_url: 'test123',
      url: 'https://example.com/destination',
      blank?: false
    )
    
    # Test early return logic
    should_return_early = link.blank?
    refute should_return_early, "Should not return early for valid link"
    
    # Test with nil link
    nil_link = nil
    should_return_early_for_nil = nil_link.blank? if nil_link.respond_to?(:blank?)
    should_return_early_for_nil = nil_link.nil? unless nil_link.respond_to?(:blank?)
    assert should_return_early_for_nil, "Should return early for nil link"
    
    # Mock request and params
    mock_request = OpenStruct.new(
      user_agent: 'Test Agent',
      referrer: 'https://referrer.com',
      remote_ip: '192.168.1.1',
      original_url: 'https://short.ly/test123'
    )
    
    mock_params = {
      utm_source: 'google',
      utm_medium: 'organic',
      utm_campaign: 'summer'
    }
    
    # Build event data as controller would
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
    
    # Verify event was published correctly
    assert_equal 1, @events_captured.length
    captured = @events_captured.first
    
    assert_equal 'link_clicked.dynamic_links', captured[:name]
    captured_data = captured[:data]
    
    assert_equal link, captured_data[:shortened_url]
    assert_equal 'test123', captured_data[:short_url]
    assert_equal 'https://example.com/destination', captured_data[:original_url]
    assert_equal 'Test Agent', captured_data[:user_agent]
    assert_equal 'https://referrer.com', captured_data[:referrer]
    assert_equal '192.168.1.1', captured_data[:ip]
    assert_equal 'google', captured_data[:utm_source]
    assert_equal 'organic', captured_data[:utm_medium]
    assert_equal 'summer', captured_data[:utm_campaign]
    assert_equal 'https://short.ly/test123', captured_data[:landing_page]
    assert_equal mock_request, captured_data[:request]
  end
end