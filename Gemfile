source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in dynamic_links.gemspec.
gemspec

gem 'dotenv-rails', require: 'dotenv/rails-now'

gem 'puma'

gem 'pg', '>= 0.18', '< 2.0'

gem 'sprockets-rails'

# for dummy app
gem 'sidekiq'

gem 'simplecov', require: false, group: :test

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

if ENV['CITUS_ENABLED'] == 'true'
  gem 'activerecord-multi-tenant'
end
