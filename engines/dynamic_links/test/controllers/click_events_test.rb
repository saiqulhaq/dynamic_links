# frozen_string_literal: true

require 'test_helper'

module DynamicLinks
  class ClickEventsTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @client = dynamic_links_clients(:one)
      @shortened_url = dynamic_links_shortened_urls(:one)
      @valid_hostname = @client.hostname
      host! @valid_hostname

      @events_captured = []
      @event_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, data|
        @events_captured << { name: name, data: data }
      end
    end

    teardown do
      ActiveSupport::Notifications.unsubscribe(@event_subscriber) if @event_subscriber
      @events_captured = []
    end

    test 'publishes link_clicked event on successful redirect' do
      get shortened_url(short_url: @shortened_url.short_url)

      assert_response :found
      assert_redirected_to @shortened_url.url
      assert_equal 1, @events_captured.length

      event = @events_captured.first
      assert_equal 'link_clicked.dynamic_links', event[:name]

      event_data = event[:data]
      assert_equal @shortened_url, event_data[:shortened_url]
      assert_equal @shortened_url.short_url, event_data[:short_url]
      assert_equal @shortened_url.url, event_data[:original_url]
      assert_not_nil event_data[:request_method]
      assert_not_nil event_data[:request_path]
      assert_not_nil event_data[:request_query_string]
    end

    test 'includes request information in click event' do
      utm_params = {
        utm_source: 'google',
        utm_medium: 'cpc',
        utm_campaign: 'test_campaign'
      }

      get shortened_url(short_url: @shortened_url.short_url), params: utm_params, headers: {
        'User-Agent' => 'Test Browser 1.0',
        'Referer' => 'https://google.com/search'
      }

      assert_response :found
      assert_equal 1, @events_captured.length

      event_data = @events_captured.first[:data]

      assert_equal 'Test Browser 1.0', event_data[:user_agent]
      assert_equal 'https://google.com/search', event_data[:referrer]
      assert_equal 'google', event_data[:utm_source]
      assert_equal 'cpc', event_data[:utm_medium]
      assert_equal 'test_campaign', event_data[:utm_campaign]
      assert_not_nil event_data[:ip]
      assert_not_nil event_data[:landing_page]
    end

    test 'does not publish event when shortened url is not found' do
      get shortened_url(short_url: 'nonexistent')

      assert_response :not_found
      assert_equal 0, @events_captured.length
    end

    test 'does not publish event when shortened url is expired' do
      expired_url = dynamic_links_shortened_urls(:expired_url)

      get shortened_url(short_url: expired_url.short_url)

      assert_response :not_found
      assert_equal 0, @events_captured.length
    end

    test 'does not publish event when client hostname is invalid' do
      host! 'invalid-hostname.com'

      get shortened_url(short_url: @shortened_url.short_url)

      assert_response :not_found
      assert_equal 0, @events_captured.length
    end

    test 'does not publish event when shortened url is blank' do
      # Test with a non-existent short URL which will result in blank/nil
      get shortened_url(short_url: 'definitely_does_not_exist')

      assert_response :not_found
      assert_equal 0, @events_captured.length
    end

    test 'handles missing utm parameters gracefully' do
      get shortened_url(short_url: @shortened_url.short_url)

      assert_response :found
      assert_equal 1, @events_captured.length

      event_data = @events_captured.first[:data]
      assert_nil event_data[:utm_source]
      assert_nil event_data[:utm_medium]
      assert_nil event_data[:utm_campaign]
    end

    test 'captures correct landing page url' do
      expected_landing_page = "http://#{@valid_hostname}/#{@shortened_url.short_url}"

      get shortened_url(short_url: @shortened_url.short_url)

      assert_response :found
      assert_equal 1, @events_captured.length

      event_data = @events_captured.first[:data]
      assert_equal expected_landing_page, event_data[:landing_page]
    end

    test 'event data includes all required fields' do
      get shortened_url(short_url: @shortened_url.short_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first[:data]

      required_fields = %i[
        shortened_url short_url original_url user_agent
        referrer ip utm_source utm_medium utm_campaign
        landing_page request_method request_path request_query_string
      ]

      required_fields.each do |field|
        assert event_data.key?(field), "Event data missing required field: #{field}"
      end
    end

    test 'event data shortened_url is the correct model instance' do
      get shortened_url(short_url: @shortened_url.short_url)

      assert_equal 1, @events_captured.length
      event_data = @events_captured.first[:data]

      shortened_url_from_event = event_data[:shortened_url]
      assert_instance_of DynamicLinks::ShortenedUrl, shortened_url_from_event
      assert_equal @shortened_url.id, shortened_url_from_event.id
      assert_equal @shortened_url.short_url, shortened_url_from_event.short_url
      assert_equal @shortened_url.url, shortened_url_from_event.url
    end
  end
end
