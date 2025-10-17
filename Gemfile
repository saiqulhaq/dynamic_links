# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.4'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.1.0.rc1'

# Efficient serialization [https://github.com/msgpack/msgpack-ruby]
gem 'msgpack', '>= 1.7.0'

# An improved asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft', '~> 1.3'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.6'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '~> 6.4'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 5.2'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Execute jobs in the background [https://github.com/mperham/sidekiq]
gem 'sidekiq', '~> 8.0'

# Admin interface [https://avohq.io]
gem 'avo'

# Application Performance Monitoring (conditionally loaded based on configuration)
require_elastic_apm = ENV.fetch('ELASTIC_APM_ENABLED', 'false').downcase == 'true'
gem 'elastic-apm', require: require_elastic_apm

group :development do
  # Detect N+1 queries and unused eager loading
  gem 'bullet'

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem 'rack-mini-profiler'

  # Live reloading for Hotwire applications [https://github.com/hotwired/spark]
  gem 'hotwire-spark', '~> 0.1'
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri mingw x64_mingw], require: 'debug/prelude'

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem 'rubocop-rails-omakase', require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'firebase_dynamic_link'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'webdrivers'

  # Engine test dependencies
  gem 'dalli', '>= 3.2.3', require: false
  gem 'mocha'
  gem 'timecop'

  # Mock Redis for testing
  gem 'mock_redis'
end

# Now using Rails 8 multi-database features
gem 'dynamic_links', path: 'engines/dynamic_links'
gem 'dynamic_links_analytics', path: 'engines/dynamic_links_analytics'
gem 'nanoid'
gem 'rack-attack', '~> 6.8'
