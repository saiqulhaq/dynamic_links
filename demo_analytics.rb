#!/usr/bin/env ruby

# Demo script to test analytics event consumption
# This simulates what happens when the dynamic_links engine publishes a click event

require_relative 'config/environment'

puts '=== Dynamic Links Analytics Event Consumption Demo ==='
puts

# Check if the analytics table is ready
if DynamicLinksAnalytics::LinkClick.table_exists?
  puts '✅ Analytics table exists and is ready'
  puts "📊 Current analytics records: #{DynamicLinksAnalytics::LinkClick.count}"
else
  puts '❌ Analytics table not found'
  exit 1
end

puts

# Simulate what the dynamic_links engine would send
mock_shortened_url = Struct.new(:client_id, :short_url, :url).new(
  'demo_client_123',
  'demo123',
  'https://example.com/landing-page'
)

demo_event_payload = {
  shortened_url: mock_shortened_url,
  short_url: 'demo123',
  original_url: 'https://example.com/landing-page',
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
  referrer: 'https://google.com/search?q=demo+test',
  ip: '203.0.113.42',
  utm_source: 'google',
  utm_medium: 'cpc',
  utm_campaign: 'summer_demo_2024',
  landing_page: 'https://short.ly/demo123?utm_source=google&utm_medium=cpc&utm_campaign=summer_demo_2024',
  request_method: 'GET',
  request_path: '/demo123',
  request_query_string: 'utm_source=google&utm_medium=cpc&utm_campaign=summer_demo_2024'
}

puts '🔥 Publishing demo event...'
puts "   Short URL: #{demo_event_payload[:short_url]}"
puts "   Original URL: #{demo_event_payload[:original_url]}"
puts "   Client ID: #{demo_event_payload[:shortened_url].client_id}"
puts "   IP: #{demo_event_payload[:ip]}"
puts "   UTM Source: #{demo_event_payload[:utm_source]}"
puts

# Process the event using the same processor that would handle real events
processor = DynamicLinksAnalytics::ClickEventProcessor.new
processor.perform(demo_event_payload)

puts '✅ Event processed successfully!'
puts

# Verify the data was stored
analytics_record = DynamicLinksAnalytics::LinkClick.last
if analytics_record
  puts '📊 Analytics record created:'
  puts "   ID: #{analytics_record.id}"
  puts "   Short URL: #{analytics_record.short_url}"
  puts "   Original URL: #{analytics_record.original_url}"
  puts "   Client ID: #{analytics_record.client_id}"
  puts "   IP Address: #{analytics_record.ip_address}"
  puts "   Clicked At: #{analytics_record.clicked_at}"
  puts "   UTM Source: #{analytics_record.metadata['utm_source']}"
  puts "   UTM Campaign: #{analytics_record.metadata['utm_campaign']}"
  puts "   User Agent: #{analytics_record.metadata['user_agent'][0..60]}..."
  puts "   Is Mobile: #{analytics_record.metadata['is_mobile']}"
  puts

  # Test the analytics queries
  puts '🔍 Testing analytics queries:'
  puts "   Total clicks for 'demo123': #{DynamicLinksAnalytics::LinkClick.clicks_count_for('demo123')}"
  puts "   Unique visitors for 'demo123': #{DynamicLinksAnalytics::LinkClick.unique_visitors_for('demo123')}"

  utm_params = analytics_record.utm_params
  puts "   UTM Parameters: #{utm_params}"
  puts "   Referrer Domain: #{analytics_record.referrer_domain}"

else
  puts '❌ No analytics record found!'
end

puts
puts '🎯 Demo completed successfully! The analytics engine is ready to consume events.'
puts

# Show current pg_stat_statements availability
if DynamicLinksAnalytics::AnalyticsService.respond_to?(:query_performance_stats)
  puts '📈 pg_stat_statements extension: Available'
  puts '   Query performance monitoring is enabled'
else
  puts '📊 pg_stat_statements extension: Not available in this environment'
end

puts
puts "Total analytics records in database: #{DynamicLinksAnalytics::LinkClick.count}"
