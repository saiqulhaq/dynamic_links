source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in dynamic_links.gemspec.
gemspec

gem 'dotenv-rails', require: 'dotenv/load'

gem 'puma'

gem 'pg', '>= 0.18', '< 2.0'

gem 'sprockets-rails'

# for dummy app
gem 'sidekiq'

group :test do
  gem 'dalli', '~> 2.7', '>= 2.7.6', require: false
  gem 'mocha'
  gem 'simplecov', require: false
  gem 'timecop'
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

require_multi_tenant = ENV['CITUS_ENABLED'] == 'true'
gem 'activerecord-multi-tenant', github: 'citusdata/activerecord-multi-tenant', branch: 'master', require: require_multi_tenant
