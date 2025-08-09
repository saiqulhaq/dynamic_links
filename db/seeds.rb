# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts '🌱 Seeding database with Dynamic Links data...'

# Create a demo client for testing
demo_client = DynamicLinks::Client.find_or_create_by!(name: 'Demo Client') do |client|
  client.api_key = 'demo_api_key_12345'
  client.scheme = 'https'
  client.hostname = 'short.example.com.local'
end

puts "✅ Created/found demo client: #{demo_client.name} (ID: #{demo_client.id})"

# Create sample shortened URLs
sample_urls = [
  {
    url: 'https://www.example.com/landing-page',
    short_url: 'demo001'
  },
  {
    url: 'https://www.example.com/products',
    short_url: 'products'
  },
  {
    url: 'https://www.example.com/about',
    short_url: 'about'
  },
  {
    url: 'https://www.example.com/contact',
    short_url: 'contact'
  },
  {
    url: 'https://docs.example.com/getting-started',
    short_url: 'docs'
  },
  {
    url: 'https://blog.example.com/latest-news',
    short_url: 'news'
  },
  {
    url: 'https://www.example.com/special-offer?utm_source=newsletter&utm_medium=email&utm_campaign=summer2024',
    short_url: 'offer'
  },
  {
    url: 'https://support.example.com/help',
    short_url: 'help'
  },
  {
    url: 'https://www.example.com/download/app',
    short_url: 'app'
  },
  {
    url: 'https://events.example.com/webinar',
    short_url: 'webinar'
  }
]

puts "\n📋 Creating sample shortened URLs..."

sample_urls.each do |url_data|
  DynamicLinks::ShortenedUrl.find_or_create_by!(
    client_id: demo_client.id,
    short_url: url_data[:short_url]
  ) do |short_link|
    short_link.url = url_data[:url]
    short_link.expires_at = 1.year.from_now
  end

  puts "   ✅ #{url_data[:short_url]} → #{url_data[:url]}"
end

# Create an additional client for multi-tenant testing
enterprise_client = DynamicLinks::Client.find_or_create_by!(name: 'Enterprise Corp') do |client|
  client.api_key = 'enterprise_api_key_67890'
  client.scheme = 'https'
  client.hostname = 'go.enterprise-corp.com.local'
end

puts "\n✅ Created/found enterprise client: #{enterprise_client.name} (ID: #{enterprise_client.id})"

# Create some enterprise URLs
enterprise_urls = [
  {
    url: 'https://www.enterprise-corp.com/quarterly-report-q3-2024',
    short_url: 'q3report'
  },
  {
    url: 'https://careers.enterprise-corp.com/senior-developer',
    short_url: 'job-dev'
  },
  {
    url: 'https://www.enterprise-corp.com/investor-relations',
    short_url: 'investors'
  }
]

puts "\n📋 Creating enterprise shortened URLs..."

enterprise_urls.each do |url_data|
  DynamicLinks::ShortenedUrl.find_or_create_by!(
    client_id: enterprise_client.id,
    short_url: url_data[:short_url]
  ) do |short_link|
    short_link.url = url_data[:url]
    short_link.expires_at = 2.years.from_now
  end

  puts "   ✅ #{url_data[:short_url]} → #{url_data[:url]}"
end

puts "\n📊 Database seeding summary:"
puts "   Total clients: #{DynamicLinks::Client.count}"
puts "   Total shortened URLs: #{DynamicLinks::ShortenedUrl.count}"
puts "   Demo client URLs: #{DynamicLinks::ShortenedUrl.where(client_id: demo_client.id).count}"
puts "   Enterprise client URLs: #{DynamicLinks::ShortenedUrl.where(client_id: enterprise_client.id).count}"

puts "\n🔗 Example short URLs created:"
puts '   https://short.example.com.local/demo001 → https://www.example.com/landing-page'
puts '   https://short.example.com.local/products → https://www.example.com/products'
puts '   https://go.enterprise-corp.com.local/q3report → https://www.enterprise-corp.com/quarterly-report-q3-2024'

puts "\n🎯 Database seeding completed successfully!"
