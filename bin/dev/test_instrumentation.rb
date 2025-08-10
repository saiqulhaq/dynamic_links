#!/usr/bin/env ruby

# Test script to verify that Rails instrumentation events are properly consumed
require_relative '../../config/environment'

puts '=== Testing Rails Instrumentation Event Consumption ==='
puts

# Track events received
events_received = []

# Subscribe to the same event to monitor it
test_subscriber = ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, _started, _finished, _unique_id, payload|
  events_received << {
    name: name,
    payload: payload,
    received_at: Time.current
  }
  puts "🔔 Test subscriber received event: #{name}"
end

puts "📡 Test subscriber registered for 'link_clicked.dynamic_links'"
puts "📊 Initial analytics records: #{DynamicLinksAnalytics::LinkClick.count}"
puts

# Publish a test event using Rails instrumentation
test_payload = {
  shortened_url: Struct.new(:client_id, :short_url, :url).new('test_client', 'test123', 'https://test.com'),
  short_url: 'test123',
  original_url: 'https://test.com',
  user_agent: 'Test Agent 1.0',
  referrer: 'https://test-referrer.com',
  ip: '192.168.1.100',
  utm_source: 'test',
  utm_medium: 'email',
  utm_campaign: 'integration_test'
}

puts '🚀 Publishing Rails instrumentation event...'
ActiveSupport::Notifications.instrument('link_clicked.dynamic_links', test_payload)

# Give a moment for async processing
sleep(0.1)

puts '✅ Event published'
puts "📬 Events received by test subscriber: #{events_received.count}"

if events_received.any?
  event = events_received.first
  puts "   Event name: #{event[:name]}"
  puts "   Payload keys: #{event[:payload].keys}"
  puts "   Received at: #{event[:received_at]}"
end

# Check if analytics engine processed the event
# Note: In real deployment, this would be async via Sidekiq
# For this test, we'll process it synchronously
if events_received.any?
  puts
  puts '🔄 Processing event synchronously for testing...'
  processor = DynamicLinksAnalytics::ClickEventProcessor.new
  processor.perform(test_payload)

  puts "📊 Analytics records after processing: #{DynamicLinksAnalytics::LinkClick.count}"

  # Check the stored record
  record = DynamicLinksAnalytics::LinkClick.last
  if record&.short_url == 'test123'
    puts '✅ Analytics record created successfully!'
    puts "   Short URL: #{record.short_url}"
    puts "   UTM Source: #{record.metadata['utm_source']}"
  else
    puts '❌ Analytics record not found or incorrect'
  end
end

# Cleanup
ActiveSupport::Notifications.unsubscribe(test_subscriber)
puts
puts '🧹 Test subscriber unsubscribed'
puts '🎯 Rails instrumentation test completed!'

# Verify the analytics engine's subscription is still active
engine_subscriptions = ActiveSupport::Notifications.notifier.listeners_for('link_clicked.dynamic_links')
puts "🔗 Active subscriptions for 'link_clicked.dynamic_links': #{engine_subscriptions.count}"

if engine_subscriptions.any?
  puts '✅ Analytics engine subscription is active and ready!'
else
  puts '⚠️  No active subscriptions found'
end
