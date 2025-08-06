# Rails Dynamic Links

This Rails app is an alternative to Firebase Dynamic Links, aiming for 100% compatibility. It provides a self-hosted URL shortener and dynamic link service.

**Core functionality is provided by the [`dynamic_links`](../dynamic_links) gem, a Rails engine included in this app.**

### Features (via `dynamic_links` gem)

- Multiple URL shortening strategies: MD5 (default), NanoId, RedisCounter, Sha256, and more
- Consistent or unique short links depending on strategy
- Fallback mode: Optionally redirect to Firebase Dynamic Links if a short link is not found
- REST API for programmatic access (can be enabled/disabled)
- Redis support for advanced strategies
- Import/export for Firebase Dynamic Links data
- Optional performance monitoring with ElasticAPM (disabled by default)

For users migrating from Firebase, download your short links data from https://takeout.google.com/takeout/custom/firebase_dynamic_links and import it on the `/import` page.

- [Explanation on YouTube](https://youtu.be/cL1ByYwAgQk?si=KXzUN5U5_JNXeQPs)
- [Diagram on draw.io](https://drive.google.com/file/d/1KwLzK7rENinnj9Zo6ZK9Y3hG3yJRtr61/view?usp=sharing)

# Project Status

Check out our [Project Board](https://github.com/users/saiqulhaq/projects/3/views/1) to see what's been completed and what's still in development.

# Documentation

- [ElasticAPM Integration](docs/elastic_apm.md) - Performance monitoring setup and usage

# Getting Started

## Prerequisites

Make sure you have the following installed on your system:

- Ruby 3.4.4
- Node.js 22+
- PostgreSQL
- Redis (optional, required for some strategies)

## Development Setup

### Using VS Code Dev Containers (Recommended)

This project includes a complete VS Code development container configuration with all dependencies pre-installed.

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
3. Clone this repository
4. Open the project in VS Code
5. When prompted, click "Reopen in Container" or run the command `Dev Containers: Reopen in Container`

The dev container will automatically:

- Set up Ruby 3.4.4
- Install Node.js 22
- Install all required system dependencies
- Install Ruby gems and Node packages
- Configure VS Code with recommended extensions and settings

### Manual Setup

If you prefer to set up the development environment manually:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/saiqulhaq/dynamic_links.git
   cd dynamic_links
   ```

2. **Copy environment variables:**

   ```bash
   cp .env.example .env
   ```

3. **Install dependencies:**

   ```bash
   bundle install
   yarn install
   ```

4. **Set up the database:**

   ```bash
   rails db:create
   rails dynamic_links:install:migrations
   rails db:migrate
   ```

5. **Start the development server:**

   ```bash
   rails server
   ```

   Visit http://localhost:3000 in your browser.

# Usage

Each shortened URL belongs to a client. Create your first client in the Rails console:

```ruby
DynamicLinks::Client.create!(name: 'Default client', api_key: 'foo', hostname: 'google.com', scheme: 'http')
```

To shorten a link via the REST API, send a POST request to `http://localhost:3000/v1/shortLinks` with this payload:

```json
{
  "api_key": "foo",
  "url": "https://github.com/rack/rack-attack"
}
```

The response will look like:

```json
{
  "shortLink": "http://google.com/a6LlbtC",
  "previewLink": "http://google.com/a6LlbtC?preview=true",
  "warning": []
}
```

# Testing

Run the test suite with:

```bash
rails test
```

To run tests with asset building:

```bash
yarn build
yarn build:css
rails test
```

# Configuration

## DynamicLinks Engine Configuration

You can configure the `dynamic_links` engine in an initializer (e.g., `config/initializers/dynamic_links.rb`). Example:

```ruby
DynamicLinks.configure do |config|
  config.shortening_strategy = :md5  # :md5, :nanoid, :redis_counter, :sha256, etc.
  config.redis_config = { host: 'localhost', port: 6379 }
  config.redis_pool_size = 10
  config.redis_pool_timeout = 3
  config.enable_rest_api = true
  config.enable_fallback_mode = false  # If true, fallback to Firebase if not found
  config.firebase_host = "https://example.app.goo.gl"  # Used for fallback
end
```

### What is Fallback Mode?

**Fallback Mode** allows your Rails app to redirect users to the original Firebase Dynamic Links service if a requested short link is not found in your local database. This is useful when you are migrating from Firebase and want to ensure that any links not yet imported or created in your self-hosted service will still work for end users.

- When `enable_fallback_mode` is set to `true`, and a short link is not found locally, the app will automatically redirect to the URL specified by `firebase_host` (with the same path and query parameters).
- When set to `false`, missing links will return a standard 404 error.

This feature helps provide a seamless migration experience from Firebase Dynamic Links to your own self-hosted solution.

See the [dynamic_links README](../dynamic_links/README.md) for all available options and strategies.

### Optional dependencies

- For `:nanoid` strategy: add `gem 'nanoid', '~> 2.0'`
- For `:redis_counter` strategy: ensure Redis is running and add `gem 'connection_pool'`

---

To configure rate limiting, edit `config/initializers/rack_attack.rb`. See https://github.com/rack/rack-attack#throttling

### Back-end

- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/) (optional, required for some strategies)
- [Sidekiq](https://github.com/mperham/sidekiq)
- [Action Cable](https://guides.rubyonrails.org/action_cable_overview.html)
- [ERB](https://guides.rubyonrails.org/layouts_and_rendering.html)

### Front-end

- [esbuild](https://esbuild.github.io/)
- [Hotwire Turbo](https://hotwired.dev/)
- [StimulusJS](https://stimulus.hotwired.dev/)
- [TailwindCSS](https://tailwindcss.com/)
- [Heroicons](https://heroicons.com/)

## Production Deployment

For production deployment, you'll need to:

1. Set up PostgreSQL and Redis servers
2. Configure environment variables in `.env` file
3. Set `RAILS_ENV=production` and `NODE_ENV=production`
4. Run `rails assets:precompile` to build assets
5. Use a process manager like systemd or supervisor to manage Rails and Sidekiq processes
6. Set up a reverse proxy (nginx/Apache) to serve static files and proxy requests

### Puma Configuration

The application uses Puma as the web server with intelligent worker configuration:

- **Default behavior**: Uses `Etc.nprocessors * 2` workers with app preloading for optimal performance
- **Containerized environments**: Set `WEB_CONCURRENCY=0` for single-process mode to avoid memory issues and child process warnings in limited memory containers (e.g., Kubernetes with 512Mi memory limit)
- **Custom worker count**: Set `WEB_CONCURRENCY=N` to use exactly N workers

**Container Deployment Recommendations:**
- For containers with ≤512Mi memory: Use `WEB_CONCURRENCY=0` (single process)
- For containers with ≥1Gi memory: Use `WEB_CONCURRENCY=1` or higher
- The configuration automatically handles SIGCHLD signals to prevent "reaped unknown child process" warnings in containerized environments

## Development Tools

- Code formatting: `bundle exec rubocop -a`
- Linting: `bundle exec rubocop`
- Asset building: `yarn build && yarn build:css`

## Environment Variables

All configuration is managed through environment variables. Copy `.env.example` to `.env` and adjust the values for your setup. Key variables include:

### Core Application
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `SECRET_KEY_BASE` - Rails secret key
- `RAILS_ENV` - Environment (development/production)

### Production Security & Networking
- `ALLOWED_HOSTS` - Comma-separated list of allowed hostnames for DNS rebinding protection (default: `example.com,*.example.com`)
- `TRUSTED_PROXIES` - Comma-separated list of CIDR ranges for trusted proxies (default: empty, configure for Kubernetes/Docker networks)
- `RACK_ATTACK_TRUSTED_IPS` - Comma-separated list of IP addresses with higher rate limits (default: empty)

### Kubernetes/Docker Deployment
For Kubernetes deployment with ConfigMap, configure these variables:
- Set `ALLOWED_HOSTS` to your domain(s), e.g., `myapp.com,*.myapp.com`
- Set `TRUSTED_PROXIES` to your cluster's CIDR ranges, e.g., `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16`
- Optionally set `RACK_ATTACK_TRUSTED_IPS` for specific IPs that need higher rate limits

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request
