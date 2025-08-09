# DynamicLinks

[![Unit Tests](https://github.com/saiqulhaq/dynamic_links/actions/workflows/unit_test.yml/badge.svg)](https://github.com/saiqulhaq/dynamic_links/actions/workflows/unit_test.yml)

DynamicLinks is a flexible URL shortening Ruby gem, designed to provide various strategies for URL shortening, similar to Firebase Dynamic Links.

By default, encoding strategies such as MD5 will generate the same short URL for the same input URL. This behavior ensures consistency and prevents the creation of multiple records for identical URLs. For scenarios requiring unique short URLs for each request, strategies like RedisCounterStrategy can be used, which generate a new short URL every time, regardless of the input URL.

## Usage

To use DynamicLinks, you need to configure the shortening strategy and other settings in an initializer or before you start shortening URLs.

### Configuration

In your Rails initializer or similar setup code, configure DynamicLinks like this:

```ruby
DynamicLinks.configure do |config|
  config.shortening_strategy = :md5  # Default strategy
  config.redis_config = { host: 'localhost', port: 6379 }  # Redis configuration
  config.redis_pool_size = 10  # Redis connection pool size
  config.redis_pool_timeout = 3  # Redis connection pool timeout in seconds
  config.enable_rest_api = true  # Enable or disable REST API feature

  # New configuration added in PR #88
  config.enable_fallback_mode = false  # When true, falls back to Firebase URL if a short link is not found
  config.firebase_host = "https://example.app.goo.gl"  # Firebase host URL for fallbacks
end
```

## Development Environment

This project supports two development environment options: GitHub Codespaces and local Docker Compose.

### Option 1: GitHub Codespaces

This project is configured to work with GitHub development containers, providing a consistent development environment.

#### Opening in GitHub Codespaces

1. Navigate to the GitHub repository
2. Click the "Code" button
3. Select the "Codespaces" tab
4. Click "Create codespace on main"

#### Development in the Codespace

Once the development container is created and set up:

1. The container includes Ruby 3.2, PostgreSQL, Redis, and other dependencies
2. Run the test suite: `cd test/dummy && bin/rails test`
3. Start the Rails server: `cd test/dummy && bin/rails server`

### Option 2: Local Development with Docker Compose

For local development, we use Docker Compose with VS Code's Remote - Containers extension.

#### Prerequisites

1. Install [Docker](https://docs.docker.com/get-docker/)
2. Install [VS Code](https://code.visualstudio.com/)
3. Install the [Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

#### Opening in VS Code with Containers

1. Clone the repository to your local machine
2. Open the project folder in VS Code
3. VS Code will detect the devcontainer configuration and prompt you to reopen in a container
4. Click "Reopen in Container"

#### Working with the Docker Compose Setup

- The setup includes three services: app (Ruby), postgres (PostgreSQL), and redis (Redis)
- Database and Redis connections are automatically configured
- Use VS Code tasks (F1 -> "Tasks: Run Task") for common operations like:
  - Starting the Rails server
  - Running tests
  - Running the Rails console
  - Managing Docker Compose services

For more details on the Docker Compose setup, refer to the [Docker Compose documentation](DOCKER_COMPOSE.md). 4. Access the application at the forwarded port (usually port 3000)

### Shortening a URL

To shorten a URL, simply call:

```ruby
shortened_url = DynamicLinks.shorten_url("https://example.com")
```

### Finding an Existing Short Link

To find an existing short link for a URL:

```ruby
short_link_data = DynamicLinks.find_short_link("https://example.com", client)
if short_link_data
  puts short_link_data[:short_url]  # e.g., "https://client.com/abc123"
  puts short_link_data[:full_url]   # e.g., "https://example.com"
else
  puts "No existing short link found"
end
```

## REST API

DynamicLinks provides a REST API for URL shortening operations when `enable_rest_api` is set to `true` in the configuration.

### Authentication

All API endpoints require an `api_key` parameter that corresponds to a registered client.

### Endpoints

#### Create Short Link

Creates a new short link for a URL.

**Endpoint:** `POST /v1/shortLinks`

**Parameters:**

- `url` (required): The URL to shorten
- `api_key` (required): Client API key

**Example Request:**

```bash
curl -X POST "http://localhost:3000/v1/shortLinks" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/long-url",
    "api_key": "your-api-key"
  }'
```

**Example Response:**

```json
{
  "shortLink": "https://your-domain.com/abc123",
  "previewLink": "https://your-domain.com/abc123?preview=true",
  "warning": []
}
```

#### Find or Create Short Link

Finds an existing short link for a URL, or creates a new one if none exists. This prevents duplicate short links for the same URL and client.

**Endpoint:** `POST /v1/shortLinks/findOrCreate`

**Parameters:**

- `url` (required): The URL to find or shorten
- `api_key` (required): Client API key

**Example Request:**

```bash
curl -X POST "http://localhost:3000/v1/shortLinks/findOrCreate" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://example.com/long-url",
    "api_key": "your-api-key"
  }'
```

**Example Response (existing link found):**

```json
{
  "shortLink": "https://your-domain.com/abc123",
  "previewLink": "https://your-domain.com/abc123?preview=true",
  "warning": []
}
```

**Example Response (new link created):**

```json
{
  "shortLink": "https://your-domain.com/def456",
  "previewLink": "https://your-domain.com/def456?preview=true",
  "warning": []
}
```

#### Expand Short Link

Retrieves the original URL from a short link.

**Endpoint:** `GET /v1/shortLinks/{short_url}`

**Parameters:**

- `short_url` (in URL): The short URL code to expand
- `api_key` (required): Client API key

**Example Request:**

```bash
curl "http://localhost:3000/v1/shortLinks/abc123?api_key=your-api-key"
```

**Example Response:**

```json
{
  "url": "https://example.com/long-url"
}
```

### Error Responses

The API returns appropriate HTTP status codes and error messages:

- `400 Bad Request`: Invalid URL format
- `401 Unauthorized`: Invalid or missing API key
- `403 Forbidden`: REST API feature is disabled
- `404 Not Found`: Short link not found (expand endpoint)
- `500 Internal Server Error`: Server error

**Example Error Response:**

```json
{
  "error": "Invalid URL"
}
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

Benchmarking scripts are available in the `benchmarks/` directory to measure performance:

- `ruby_api.rb`: Benchmarks Ruby API URL shortening performance
- `rest_api.py`: Benchmarks REST API URL shortening performance
- `create_or_find.rb`: Compares performance of different `create_or_find` methods

You can run these benchmarks to measure performance in your specific environment.

## How to run the unit test

### When using a Plain PostgreSQL DB

```bash
rails db:setup
rails db:test:prepare
rails test
```

## Events and Analytics Integration

The DynamicLinks engine publishes Rails instrumentation events that can be consumed by analytics engines or other services to track link usage and gather insights.

### Event Publishing

When a shortened link is accessed and redirected, the engine publishes a `link_clicked.dynamic_links` event using Rails' `ActiveSupport::Notifications` system. This approach provides a clean separation of concerns - the dynamic_links engine focuses on URL shortening while other engines can handle analytics.

### Published Events

#### `link_clicked.dynamic_links`

This event is triggered when a shortened link is successfully accessed and before the redirect occurs.

**Event Payload:**

```ruby
{
  shortened_url: ShortenedUrl,  # The ShortenedUrl model instance
  short_url: String,            # The short URL identifier (e.g., "abc123")
  original_url: String,         # The original destination URL
  user_agent: String,           # Browser user agent string
  referrer: String,             # HTTP referrer header (may be nil)
  ip: String,                   # Client IP address
  utm_source: String,           # UTM source parameter (may be nil)
  utm_medium: String,           # UTM medium parameter (may be nil)
  utm_campaign: String,         # UTM campaign parameter (may be nil)
  landing_page: String,         # The full requested URL including parameters
  request: ActionDispatch::Request  # The full Rails request object
}
```

### Consuming Events

To consume these events in your application, create a subscriber:

```ruby
# In an initializer or engine
ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, payload|
  # Handle the click event
  shortened_url = payload[:shortened_url]

  # Example: Log the click
  Rails.logger.info "Link clicked: #{payload[:short_url]} -> #{payload[:original_url]}"

  # Example: Track analytics
  YourAnalyticsService.track_click(
    short_url: payload[:short_url],
    original_url: payload[:original_url],
    user_agent: payload[:user_agent],
    ip: payload[:ip],
    referrer: payload[:referrer],
    utm_params: {
      source: payload[:utm_source],
      medium: payload[:utm_medium],
      campaign: payload[:utm_campaign]
    }
  )
end
```

### Analytics Engine Integration

For a complete analytics solution, consider using the companion `dynamic_links_analytics` engine, which automatically subscribes to these events and provides:

- Visit tracking and analytics
- Click metrics and reporting
- UTM parameter analysis
- Geographic and device analytics (when configured)

See the `engines/dynamic_links_analytics` documentation for more details on setting up comprehensive analytics.

### Event Documentation

For complete event documentation including payload structure and implementation details, see [EVENTS.md](docs/EVENTS.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

- [ ] add more test to test security issue by malicious hacker "engines/dynamic_links/test/integration/"
