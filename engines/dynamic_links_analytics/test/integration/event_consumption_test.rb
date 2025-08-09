require 'test_helper'

module DynamicLinksAnalytics
  class EventConsumptionTest < ActiveSupport::TestCase
    test 'should consume link_clicked event and create analytics record' do
      # Mock event payload similar to what dynamic_links engine would send
      mock_shortened_url = Struct.new(:client_id, :short_url, :url).new(
        123,
        'abc123',
        'https://example.com'
      )

      event_payload = {
        shortened_url: mock_shortened_url,
        short_url: 'abc123',
        original_url: 'https://example.com',
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        referrer: 'https://google.com/search?q=test',
        ip: '192.168.1.100',
        utm_source: 'google',
        utm_medium: 'cpc',
        utm_campaign: 'summer_campaign',
        landing_page: 'https://short.ly/abc123?utm_source=google&utm_medium=cpc',
        request_method: 'GET',
        request_path: '/abc123',
        request_query_string: 'utm_source=google&utm_medium=cpc'
      }

      # Verify no analytics records exist initially
      assert_equal 0, LinkClick.count

      # Process the event synchronously for testing
      processor = ClickEventProcessor.new
      processor.perform(event_payload)

      # Verify analytics record was created
      assert_equal 1, LinkClick.count

      link_click = LinkClick.first
      assert_equal 'abc123', link_click.short_url
      assert_equal 'https://example.com', link_click.original_url
      assert_equal 123, link_click.client_id
      assert_equal '192.168.1.100', link_click.ip_address.to_s

      # Verify metadata
      assert_equal 'google', link_click.metadata['utm_source']
      assert_equal 'cpc', link_click.metadata['utm_medium']
      assert_equal 'summer_campaign', link_click.metadata['utm_campaign']
      assert_equal 'https://google.com/search?q=test', link_click.metadata['referrer']
      assert_not_nil link_click.metadata['processed_at']
    end

    test 'should handle event with minimal payload' do
      mock_shortened_url = Struct.new(:client_id, :short_url, :url).new(
        456,
        'minimal123',
        'https://minimal.com'
      )

      event_payload = {
        shortened_url: mock_shortened_url,
        short_url: 'minimal123',
        original_url: 'https://minimal.com',
        ip: '10.0.0.1'
      }

      processor = ClickEventProcessor.new
      processor.perform(event_payload)

      assert_equal 1, LinkClick.count
      link_click = LinkClick.first
      assert_equal 'minimal123', link_click.short_url
      assert_equal 'https://minimal.com', link_click.original_url
      assert_equal 456, link_click.client_id
      assert_equal '10.0.0.1', link_click.ip_address.to_s
    end

    test 'should handle invalid event payload gracefully' do
      # Test with nil payload
      processor = ClickEventProcessor.new

      # Should not raise an error
      assert_nothing_raised do
        processor.perform(nil)
      end

      assert_equal 0, LinkClick.count
    end

    test 'should fail when client_id is missing' do
      mock_shortened_url = Struct.new(:client_id, :short_url, :url).new(
        nil,
        'no_client',
        'https://noclient.com'
      )

      event_payload = {
        shortened_url: mock_shortened_url,
        short_url: 'no_client',
        original_url: 'https://noclient.com',
        ip: '10.0.0.1'
      }

      processor = ClickEventProcessor.new

      # Should raise an error when client_id is missing
      assert_raises(ArgumentError, 'client_id is required for analytics tracking') do
        processor.perform(event_payload)
      end

      assert_equal 0, LinkClick.count
    end

    test 'should extract browser and device information' do
      mock_shortened_url = Struct.new(:client_id, :short_url, :url).new(
        789,
        'mobile123',
        'https://mobile.com'
      )

      mobile_user_agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148'

      event_payload = {
        shortened_url: mock_shortened_url,
        short_url: 'mobile123',
        original_url: 'https://mobile.com',
        ip: '192.168.1.200',
        user_agent: mobile_user_agent
      }

      processor = ClickEventProcessor.new
      processor.perform(event_payload)

      link_click = LinkClick.first
      assert_equal true, link_click.metadata['is_mobile']
      assert_equal mobile_user_agent, link_click.metadata['user_agent']
    end

    test 'should track UTM parameters correctly' do
      mock_shortened_url = Struct.new(:client_id, :short_url, :url).new(
        999,
        'utm123',
        'https://utm-test.com'
      )

      event_payload = {
        shortened_url: mock_shortened_url,
        short_url: 'utm123',
        original_url: 'https://utm-test.com',
        ip: '203.0.113.1',
        utm_source: 'newsletter',
        utm_medium: 'email',
        utm_campaign: 'product_launch_2024',
        referrer: 'https://mailchimp.com'
      }

      processor = ClickEventProcessor.new
      processor.perform(event_payload)

      link_click = LinkClick.first
      utm_params = link_click.utm_params

      assert_equal 'newsletter', utm_params[:source]
      assert_equal 'email', utm_params[:medium]
      assert_equal 'product_launch_2024', utm_params[:campaign]
      assert_equal 'https://mailchimp.com', link_click.metadata['referrer']
    end
  end
end
