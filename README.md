# DynamicLinks

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

## How to run the unit test

### When using a Plain PostgreSQL DB

```bash
rails db:setup
rails db:test:prepare
rails test
```

### When using PostgreSQL DB with Citus

```bash
export CITUS_ENABLED=true
rails db:setup
rails db:test:prepare
rails test
```

Note:
Make sure the Citus extension already enabled on the installed PostgreSQL
We don't manage it on Rails.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
