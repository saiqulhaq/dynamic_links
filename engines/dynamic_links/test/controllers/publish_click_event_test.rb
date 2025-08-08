# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class PublishClickEventTest < ActionController::TestCase
    tests RedirectsController

    setup do
      @client = dynamic_links_clients(:one)
      @shortened_url = dynamic_links_shortened_urls(:one)
      @controller.request.host = @client.hostname

      @events_captured = []
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        @events_captured << data
      end
    end

    teardown do
      ActiveSupport::Notifications.unsubscribe(@event_subscriber) if @event_subscriber
      @events_captured = []
    end

    test 'publish_click_event method publishes correct data structure' do
      # Set up request attributes
      @controller.request.stubs(:ip).returns('192.168.1.100')
      @controller.request.user_agent = 'Test Agent'
      @controller.request.headers['Referer'] = 'https://example.com/referrer'
      @controller.params = ActionController::Parameters.new({
                                                              utm_source: 'test_source',
                                                              utm_medium: 'test_medium',
                                                              utm_campaign: 'test_campaign'
                                                            })

      # Call the private method directly for testing
      @controller.send(:publish_click_event, @shortened_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first

      assert_equal @shortened_url, event_data[:shortened_url]
      assert_equal @shortened_url.short_url, event_data[:short_url]
      assert_equal @shortened_url.url, event_data[:original_url]
      assert_equal 'Test Agent', event_data[:user_agent]
      assert_equal 'https://example.com/referrer', event_data[:referrer]
      assert_equal '192.168.1.100', event_data[:ip]
      assert_equal 'test_source', event_data[:utm_source]
      assert_equal 'test_medium', event_data[:utm_medium]
      assert_equal 'test_campaign', event_data[:utm_campaign]
      assert_not_nil event_data[:landing_page]
      assert_not_nil event_data[:request_method]
      assert_not_nil event_data[:request_path]
      assert_not_nil event_data[:request_query_string]
    end

    test 'publish_click_event handles nil shortened_url gracefully' do
      @controller.send(:publish_click_event, nil)

      assert_equal 0, @events_captured.length
    end

    test 'publish_click_event handles missing utm parameters' do
      @controller.params = ActionController::Parameters.new({})

      @controller.send(:publish_click_event, @shortened_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first

      assert_nil event_data[:utm_source]
      assert_nil event_data[:utm_medium]
      assert_nil event_data[:utm_campaign]
    end

    test 'publish_click_event includes request information' do
      @controller.send(:publish_click_event, @shortened_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first

      assert_not_nil event_data[:request_method]
      assert_not_nil event_data[:request_path]
      assert_not_nil event_data[:request_query_string]
      assert_equal @controller.request.method, event_data[:request_method]
      assert_equal @controller.request.path, event_data[:request_path]
      assert_equal @controller.request.query_string, event_data[:request_query_string]
    end

    test 'publish_click_event captures landing page URL correctly' do
      expected_url = @controller.request.original_url

      @controller.send(:publish_click_event, @shortened_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first

      assert_equal expected_url, event_data[:landing_page]
    end

    test 'publish_click_event works with partial utm parameters' do
      @controller.params = ActionController::Parameters.new({
                                                              utm_source: 'partial_test',
                                                              utm_campaign: 'campaign_only'
                                                              # utm_medium is missing
                                                            })

      @controller.send(:publish_click_event, @shortened_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first

      assert_equal 'partial_test', event_data[:utm_source]
      assert_nil event_data[:utm_medium]
      assert_equal 'campaign_only', event_data[:utm_campaign]
    end

    test 'publish_click_event handles missing request headers' do
      @controller.request.stubs(:user_agent).returns(nil)
      @controller.request.stubs(:referrer).returns(nil)

      @controller.send(:publish_click_event, @shortened_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first

      # Should still work, just with nil values
      assert event_data.key?(:user_agent)
      assert event_data.key?(:referrer)
      assert_nil event_data[:user_agent]
      assert_nil event_data[:referrer]
    end
  end
end
