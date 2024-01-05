# DynamicLinks

DynamicLinks is a flexible URL shortening Ruby gem, designed to provide various strategies for URL shortening, similar to Firebase Dynamic Links.

By default, encoding strategies such as MD5 will generate the same short URL for the same input URL. This behavior ensures consistency and prevents the creation of multiple records for identical URLs. For scenarios requiring unique short URLs for each request, strategies like RedisCounterStrategy can be used, which generate a new short URL every time, regardless of the input URL.

## Usage

To use DynamicLinks, you need to configure the shortening strategy and other settings in an initializer or before you start shortening URLs.

### Configuration

In your Rails initializer or similar setup code, configure DynamicLinks like this:

```ruby
DynamicLinks.configure do |config|
  config.shortening_strategy = :MD5  # Default strategy
  config.redis_config = { host: 'localhost', port: 6379 }  # Redis configuration
  config.redis_pool_size = 10  # Redis connection pool size
  config.redis_pool_timeout = 3  # Redis connection pool timeout in seconds
  config.enable_rest_api = true  # Enable or disable REST API feature
end
```

### Shortening a URL

To shorten a URL, simply call:

```ruby
shortened_url = DynamicLinks.shorten_url("https://example.com")
```

## Available Shortening Strategies

DynamicLinks supports various shortening strategies. The default strategy is `MD5`, but you can choose among several others, including `NanoIdStrategy`, `RedisCounterStrategy`, `Sha256Strategy`, and more.

Depending on the strategy you choose, you may need to install additional dependencies.

### Optional Dependencies

- For `NanoIdStrategy`, add `gem 'nanoid', '~> 2.0'` to your Gemfile.
- For `RedisCounterStrategy`, ensure Redis is available and configured. Redis strategy requires `connection_pool` gem too.

Ensure you bundle these dependencies along with the DynamicLinks gem if you plan to use these strategies.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "dynamic_links"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install dynamic_links
```

## Performance

Shorten an URL using Ruby:
Shorten an URL using API:

## Contributing

We welcome contributions to DynamicLinks! Please read the contributing guidelines to get started.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
