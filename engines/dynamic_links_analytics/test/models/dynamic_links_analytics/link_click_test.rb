require 'test_helper'

module DynamicLinksAnalytics
  class LinkClickTest < ActiveSupport::TestCase
    test 'should create link click with valid attributes' do
      link_click = LinkClick.new(
        short_url: 'abc123',
        original_url: 'https://example.com',
        client_id: 1,
        ip_address: '192.168.1.1',
        clicked_at: Time.current,
        metadata: {
          user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          referrer: 'https://google.com',
          utm_source: 'google',
          utm_medium: 'cpc',
          utm_campaign: 'summer_sale'
        }
      )

      assert link_click.valid?
      assert link_click.save
    end

    test 'should validate presence of required fields' do
      link_click = LinkClick.new

      assert_not link_click.valid?
      assert_includes link_click.errors[:short_url], "can't be blank"
      assert_includes link_click.errors[:original_url], "can't be blank"
      assert_includes link_click.errors[:client_id], "can't be blank"
      assert_includes link_click.errors[:clicked_at], "can't be blank"
      assert_includes link_click.errors[:ip_address], "can't be blank"
    end

    test 'should validate URL format' do
      link_click = LinkClick.new(
        short_url: 'abc123',
        original_url: 'not_a_url',
        client_id: 1,
        ip_address: '192.168.1.1',
        clicked_at: Time.current
      )

      assert_not link_click.valid?
      assert_includes link_click.errors[:original_url], 'is invalid'
    end

    test 'should extract UTM parameters from metadata' do
      link_click = LinkClick.create!(
        short_url: 'abc123',
        original_url: 'https://example.com',
        client_id: 1,
        ip_address: '192.168.1.1',
        clicked_at: Time.current,
        metadata: {
          utm_source: 'google',
          utm_medium: 'cpc',
          utm_campaign: 'summer_sale'
        }
      )

      utm_params = link_click.utm_params
      assert_equal 'google', utm_params[:source]
      assert_equal 'cpc', utm_params[:medium]
      assert_equal 'summer_sale', utm_params[:campaign]
    end

    test 'should extract referrer domain' do
      link_click = LinkClick.create!(
        short_url: 'abc123',
        original_url: 'https://example.com',
        client_id: 1,
        ip_address: '192.168.1.1',
        clicked_at: Time.current,
        metadata: {
          referrer: 'https://www.google.com/search?q=test'
        }
      )

      assert_equal 'www.google.com', link_click.referrer_domain
    end

    test 'should handle scopes correctly' do
      # Create test data
      LinkClick.create!(
        short_url: 'abc123',
        original_url: 'https://example.com',
        client_id: 1,
        ip_address: '192.168.1.1',
        clicked_at: 2.days.ago,
        metadata: { utm_source: 'google' }
      )

      LinkClick.create!(
        short_url: 'abc123',
        original_url: 'https://example.com',
        client_id: 1,
        ip_address: '192.168.1.2',
        clicked_at: 1.day.ago,
        metadata: { utm_source: 'facebook' }
      )

      LinkClick.create!(
        short_url: 'def456',
        original_url: 'https://example.com',
        client_id: 2,
        ip_address: '192.168.1.3',
        clicked_at: Time.current,
        metadata: { utm_source: 'google' }
      )

      # Test scopes
      assert_equal 2, LinkClick.for_short_url('abc123').count
      assert_equal 1, LinkClick.for_short_url('def456').count
      assert_equal 2, LinkClick.for_client(1).count
      assert_equal 2, LinkClick.with_utm_source('google').count
      assert_equal 1, LinkClick.with_utm_source('facebook').count
    end

    test 'should calculate analytics correctly' do
      # Create test data
      3.times do |i|
        LinkClick.create!(
          short_url: 'abc123',
          original_url: 'https://example.com',
          client_id: 1,
          ip_address: "192.168.1.#{i + 1}",
          clicked_at: Time.current,
          metadata: {}
        )
      end

      # Same IP for one click (testing unique visitors)
      LinkClick.create!(
        short_url: 'abc123',
        original_url: 'https://example.com',
        client_id: 1,
        ip_address: '192.168.1.1',
        clicked_at: Time.current,
        metadata: {}
      )

      assert_equal 4, LinkClick.clicks_count_for('abc123')
      assert_equal 3, LinkClick.unique_visitors_for('abc123')
    end
  end
end
