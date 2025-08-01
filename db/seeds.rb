# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create development admin user for testing
if Rails.env.development?
  puts "Creating development admin user..."
  
  admin_user = User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.name = 'Admin User'
    user.provider = 'google'
    user.uid = 'admin@example.com'
    user.admin = true
  end
  
  puts "✓ Admin user created: #{admin_user.email} (admin: #{admin_user.admin?})"
  
  # Create a regular user for testing
  regular_user = User.find_or_create_by!(email: 'user@example.com') do |user|
    user.name = 'Regular User'
    user.provider = 'google'
    user.uid = 'user@example.com'
    user.admin = false
  end
  
  puts "✓ Regular user created: #{regular_user.email} (admin: #{regular_user.admin?})"
end

# Create sample Dynamic Links client for testing
puts "Creating sample Dynamic Links client..."

sample_client = DynamicLinks::Client.find_or_create_by!(name: 'Sample Client') do |client|
  client.api_key = SecureRandom.hex(32)
  client.scheme = 'https'
  client.hostname = 'short.example.com'
end

puts "✓ Sample client created: #{sample_client.name}"

# Create sample shortened URLs
puts "Creating sample shortened URLs..."

['home', 'about', 'contact'].each do |path|
  shortened_url = DynamicLinks::ShortenedUrl.find_or_create_by!(
    client: sample_client,
    short_url: path
  ) do |url|
    url.url = "https://example.com/#{path}"
    url.expires_at = 1.year.from_now
  end
  
  puts "✓ Sample URL created: #{path} -> #{shortened_url.url}"
end

puts "🎉 Seeding completed!"
