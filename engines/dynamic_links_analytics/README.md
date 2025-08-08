# Dynamic Links Analytics

Analytics plugin for Dynamic Links engine that provides PostgreSQL-optimized tracking and analysis capabilities.

## Features

- PostgreSQL-specific optimizations with pg_stat_statements
- JSONB indexing for efficient analytics queries
- Event-driven architecture for seamless integration with Dynamic Links core

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamic_links_analytics'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install dynamic_links_analytics
```

## Requirements

- PostgreSQL database
- Rails 5.0+
- dynamic_links gem

## Usage

This gem automatically subscribes to Dynamic Links events and tracks analytics data using PostgreSQL-optimized structures.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/saiqulhaq/dynamic_links_analytics.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
