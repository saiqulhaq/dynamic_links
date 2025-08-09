#!/usr/bin/env ruby

# Test script to simulate clicking a seeded short URL and verify analytics are generated
require_relative 'config/environment'

puts '=== Testing Analytics with Seeded Data ==='
puts

# Get a demo short URL
demo_url = DynamicLinks::ShortenedUrl.joins(:client)
                                     .where(client: { name: 'Demo Client' })
                                     .first

if demo_url.nil?
  puts "❌ No demo URLs found. Please run 'bin/rails db:seed' first."
  exit 1
end

puts '🔗 Using seeded short URL:'
puts "   Short: #{demo_url.short_url}"
puts "   Original: #{demo_url.url}"
puts "   Client: #{demo_url.client.name}"
puts

# Check initial analytics count
initial_count = DynamicLinksAnalytics::LinkClick.count
puts "📊 Initial analytics records: #{initial_count}"

# Simulate the event that would be published by the dynamic_links engine
event_payload = {
  shortened_url: demo_url,
  short_url: demo_url.short_url,
  original_url: demo_url.url,
  user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
  referrer: 'https://twitter.com/some-post',
  ip: '203.0.113.100',
  utm_source: 'twitter',
  utm_medium: 'social',
  utm_campaign: 'demo_test_2024',
  landing_page: "https://#{demo_url.client.hostname}/#{demo_url.short_url}?utm_source=twitter&utm_medium=social&utm_campaign=demo_test_2024",
  request_method: 'GET',
  request_path: "/#{demo_url.short_url}",
  request_query_string: 'utm_source=twitter&utm_medium=social&utm_campaign=demo_test_2024'
}

puts '🚀 Simulating link click event...'

# Publish the event using Rails instrumentation (same as the dynamic_links engine would)
ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', event_payload)

# Process the event synchronously for immediate verification
# (In production, this would be handled asynchronously by Sidekiq)
serializable_payload = event_payload.except(:shortened_url)
serializable_payload[:client_id] = demo_url.client_id

processor = DynamicLinksAnalytics::ClickEventProcessor.new
processor.perform(serializable_payload)

puts '✅ Event processed'

# Verify analytics record was created
final_count = DynamicLinksAnalytics::LinkClick.count
new_records = final_count - initial_count

puts "\n📈 Analytics Results:"
puts "   Records before: #{initial_count}"
puts "   Records after: #{final_count}"
puts "   New records: #{new_records}"

if new_records > 0
  latest_record = DynamicLinksAnalytics::LinkClick.last
  puts "\n📊 Latest Analytics Record:"
  puts "   ID: #{latest_record.id}"
  puts "   Short URL: #{latest_record.short_url}"
  puts "   Original URL: #{latest_record.original_url}"
  puts "   Client ID: #{latest_record.client_id}"
  puts "   IP Address: #{latest_record.ip_address}"
  puts "   Clicked At: #{latest_record.clicked_at}"
  puts "   UTM Source: #{latest_record.metadata['utm_source']}"
  puts "   UTM Medium: #{latest_record.metadata['utm_medium']}"
  puts "   UTM Campaign: #{latest_record.metadata['utm_campaign']}"
  puts "   Referrer: #{latest_record.metadata['referrer']}"
  puts "   Is Mobile: #{latest_record.metadata['is_mobile']}"

  # Test analytics queries
  puts "\n🔍 Analytics Queries:"
  puts "   Total clicks for '#{demo_url.short_url}': #{DynamicLinksAnalytics::LinkClick.clicks_count_for(demo_url.short_url)}"
  puts "   Unique visitors for '#{demo_url.short_url}': #{DynamicLinksAnalytics::LinkClick.unique_visitors_for(demo_url.short_url)}"
  puts "   UTM Sources: #{DynamicLinksAnalytics::LinkClick.utm_source_breakdown}"

  puts "\n🎯 Test completed successfully! Analytics are working with seeded data."
else
  puts "\n❌ No analytics records were created. Please check the implementation."
end
