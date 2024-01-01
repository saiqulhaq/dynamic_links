# DynamicLinks

DynamicLinks is a flexible URL shortening Ruby gem, designed to provide various strategies for URL shortening, similar to Firebase Dynamic Links.

## Usage

To use DynamicLinks, you need to configure the shortening strategy in an initializer or before you start shortening URLs.

### Configuration

In your Rails initializer or similar setup code, configure DynamicLinks like this:

```ruby
DynamicLinks.configure do |config|
  config.shortening_strategy = :MD5
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
- For `RedisCounterStrategy`, add `gem 'redis', '>= 4'` to your Gemfile.

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

## Contributing

We welcome contributions to DynamicLinks! Please read the contributing guidelines to get started.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
