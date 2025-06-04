source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in dynamic_links.gemspec.
gemspec

gem 'dotenv-rails', require: 'dotenv/rails-now'

gem 'puma'

gem 'pg', '>= 0.18', '< 2.0'

gem 'sprockets-rails', '>= 3.5.2'

# for dummy app
gem 'sidekiq'

group :test do
  gem 'simplecov', require: false
  gem 'mocha'
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

if ENV['CITUS_ENABLED'] == 'true'
  # need to use Github version for MultiTenant
  # because the gem version is not compatible with Rails 8
  # and we need to use the latest features
  gem 'activerecord-multi-tenant', github: 'citusdata/activerecord-multi-tenant'
end
