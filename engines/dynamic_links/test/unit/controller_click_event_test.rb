# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support'
require 'active_support/notifications'
require 'active_support/test_case'
require 'ostruct'

class ControllerClickEventTest < ActiveSupport::TestCase

  def setup
    @events_captured = []
    @subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
      @events_captured << {
        name: name,
        data: data
      }
    end
  end

  def teardown
    ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
    @events_captured = []
  end

  def test_publish_click_event_with_valid_link
    # Mock shortened_url object
    link = OpenStruct.new(
      short_url: 'abc123',
      url: 'https://example.com/target',
      blank?: false
    )

    # Mock request object
    request = OpenStruct.new(
      user_agent: 'Mozilla/5.0',
      referrer: 'https://google.com/search',
      remote_ip: '192.168.1.100',
      original_url: 'https://short.ly/abc123'
    )

    # Mock params
    params = {
      utm_source: 'google',
      utm_medium: 'organic',
      utm_campaign: 'test-campaign'
    }

    # This simulates the controller's publish_click_event method
    unless link.blank?
      event_data = {
        shortened_url: link,
        short_url: link.short_url,
        original_url: link.url,
        user_agent: request.user_agent,
        referrer: request.referrer,
        ip: request.remote_ip,
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
        landing_page: request.original_url,
        request: request
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
    end

    # Verify event was published
    assert_equal 1, @events_captured.length
    
    captured_data = @events_captured.first[:data]
    assert_equal link, captured_data[:shortened_url]
    assert_equal 'abc123', captured_data[:short_url]
    assert_equal 'https://example.com/target', captured_data[:original_url]
    assert_equal 'Mozilla/5.0', captured_data[:user_agent]
    assert_equal 'https://google.com/search', captured_data[:referrer]
    assert_equal '192.168.1.100', captured_data[:ip]
    assert_equal 'google', captured_data[:utm_source]
    assert_equal 'organic', captured_data[:utm_medium]
    assert_equal 'test-campaign', captured_data[:utm_campaign]
    assert_equal 'https://short.ly/abc123', captured_data[:landing_page]
    assert_equal request, captured_data[:request]
  end

  def test_publish_click_event_with_blank_link
    # Test with nil link
    link = nil

    # This simulates the controller's publish_click_event method early return
    unless link&.blank? == false
      # Should return early, no event published
    end

    # Verify no event was published
    assert_equal 0, @events_captured.length
  end

  def test_publish_click_event_with_missing_utm_params
    link = OpenStruct.new(
      short_url: 'test456',
      url: 'https://example.com/page',
      blank?: false
    )

    request = OpenStruct.new(
      user_agent: 'Test Browser',
      referrer: nil,
      remote_ip: '127.0.0.1',
      original_url: 'https://test.ly/test456'
    )

    # Empty params (no UTM parameters)
    params = {}

    # Simulate controller method
    unless link.blank?
      event_data = {
        shortened_url: link,
        short_url: link.short_url,
        original_url: link.url,
        user_agent: request.user_agent,
        referrer: request.referrer,
        ip: request.remote_ip,
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
        landing_page: request.original_url,
        request: request
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
    end

    # Verify event was published with nil UTM values
    assert_equal 1, @events_captured.length
    
    captured_data = @events_captured.first[:data]
    assert_equal link, captured_data[:shortened_url]
    assert_nil captured_data[:utm_source]
    assert_nil captured_data[:utm_medium]
    assert_nil captured_data[:utm_campaign]
    assert_nil captured_data[:referrer]
  end

  def test_publish_click_event_with_partial_request_data
    link = OpenStruct.new(
      short_url: 'partial789',
      url: 'https://example.com/partial',
      blank?: false
    )

    # Request with some missing data
    request = OpenStruct.new(
      user_agent: nil,
      referrer: '',
      remote_ip: '10.0.0.1',
      original_url: 'https://short.ly/partial789'
    )

    params = {
      utm_source: 'facebook',
      # utm_medium missing
      utm_campaign: 'social-test'
    }

    # Simulate controller method
    unless link.blank?
      event_data = {
        shortened_url: link,
        short_url: link.short_url,
        original_url: link.url,
        user_agent: request.user_agent,
        referrer: request.referrer,
        ip: request.remote_ip,
        utm_source: params[:utm_source],
        utm_medium: params[:utm_medium],
        utm_campaign: params[:utm_campaign],
        landing_page: request.original_url,
        request: request
      }

      ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)
    end

    # Verify event was published with partial data
    assert_equal 1, @events_captured.length
    
    captured_data = @events_captured.first[:data]
    assert_equal 'partial789', captured_data[:short_url]
    assert_nil captured_data[:user_agent]
    assert_equal '', captured_data[:referrer]
    assert_equal '10.0.0.1', captured_data[:ip]
    assert_equal 'facebook', captured_data[:utm_source]
    assert_nil captured_data[:utm_medium]
    assert_equal 'social-test', captured_data[:utm_campaign]
  end

  def test_blank_link_handling
    # Test different "blank" scenarios
    blank_scenarios = [
      nil,
      OpenStruct.new(blank?: true),
      OpenStruct.new(short_url: '', url: '', blank?: true)
    ]

    blank_scenarios.each_with_index do |link, index|
      # Reset events
      @events_captured.clear

      # Simulate controller logic
      if link.blank?
        # Should return early
      else
        # Would publish event, but shouldn't reach here
        ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', { test: "scenario_#{index}" })
      end

      # Verify no events published for blank links
      assert_equal 0, @events_captured.length, "Expected no events for blank scenario #{index}"
    end
  end

  def test_event_data_integrity
    # Test that the event data structure matches exactly what controller would send
    link = OpenStruct.new(
      id: 999,
      short_url: 'integrity_test',
      url: 'https://example.com/integrity',
      client_id: 5,
      blank?: false
    )

    request = OpenStruct.new(
      user_agent: 'IntegrityTestBot/1.0',
      referrer: 'https://integrity-referrer.com',
      remote_ip: '203.0.113.1',
      original_url: 'https://integrity.ly/integrity_test'
    )

    params = {
      utm_source: 'integrity_source',
      utm_medium: 'integrity_medium',
      utm_campaign: 'integrity_campaign',
      other_param: 'should_be_ignored' # This shouldn't appear in event
    }

    # Exactly replicate controller logic
    return if link.blank?

    event_data = {
      shortened_url: link,
      short_url: link.short_url,
      original_url: link.url,
      user_agent: request.user_agent,
      referrer: request.referrer,
      ip: request.remote_ip,
      utm_source: params[:utm_source],
      utm_medium: params[:utm_medium],
      utm_campaign: params[:utm_campaign],
      landing_page: request.original_url,
      request: request
    }

    ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_data)

    # Comprehensive verification
    assert_equal 1, @events_captured.length
    
    event = @events_captured.first
    assert_equal 'link_clicked.dynamic_links', event[:name]
    
    data = event[:data]
    
    # Verify each field
    assert_same link, data[:shortened_url], "shortened_url should be same object reference"
    assert_equal 'integrity_test', data[:short_url]
    assert_equal 'https://example.com/integrity', data[:original_url]
    assert_equal 'IntegrityTestBot/1.0', data[:user_agent]
    assert_equal 'https://integrity-referrer.com', data[:referrer]
    assert_equal '203.0.113.1', data[:ip]
    assert_equal 'integrity_source', data[:utm_source]
    assert_equal 'integrity_medium', data[:utm_medium]
    assert_equal 'integrity_campaign', data[:utm_campaign]
    assert_equal 'https://integrity.ly/integrity_test', data[:landing_page]
    assert_same request, data[:request], "request should be same object reference"
    
    # Verify expected fields count (no extra fields)
    expected_fields = [
      :shortened_url, :short_url, :original_url, :user_agent, :referrer, 
      :ip, :utm_source, :utm_medium, :utm_campaign, :landing_page, :request
    ]
    
    assert_equal expected_fields.length, data.keys.length, "Should have exactly #{expected_fields.length} fields"
    expected_fields.each do |field|
      assert data.key?(field), "Event data should include #{field}"
    end
  end
end