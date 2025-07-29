# Rails dynamic links

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

This Rails app is based on the ![Docker Rails Example](https://github.com/nickjj/docker-rails-example?ref=https://github.com/saiqulhaq/rails_dynamic_links) project.

* [Explanation on YouTube](https://youtu.be/cL1ByYwAgQk?si=KXzUN5U5_JNXeQPs)
* [Diagram on draw.io](https://drive.google.com/file/d/1KwLzK7rENinnj9Zo6ZK9Y3hG3yJRtr61/view?usp=sharing)

# Project Status
Check out our [Project Board](https://github.com/users/saiqulhaq/projects/3/views/1) to see what's been completed and what's still in development.

# Documentation

- [ElasticAPM Integration](docs/elastic_apm.md) - Performance monitoring setup and usage
- [Docker ElasticAPM Setup](docs/docker_elastic_apm.md) - How to use ElasticAPM with Docker Compose

# Usage

Import the migration files from the `dynamic_links` gem:

```bash
bin/rails db:create
bin/rails dynamic_links:install:migrations
bin/rails db:migrate
```

Each shortened URL belongs to a client. Create your first client in the Rails console:

```ruby
DynamicLinks::Client.create!(name: 'Default client', api_key: 'foo', hostname: 'google.com', scheme: 'http')
```

To shorten a link via the REST API, send a POST request to `http://localhost:8000/v1/shortLinks` with this payload:

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


#### Setup the initial database:

```sh
# You can run this from a 2nd terminal.
./run rails db:setup
```

*We'll go over that `./run` script in a bit!*

#### Check it out in a browser:

Visit <http://localhost:8000> in your favorite browser.

#### Running the test suite:

```sh
# You can run this from the same terminal as before.
./run test
```

You can also run `./run test -b` with does the same thing but builds your JS
and CSS bundles. This could come in handy in fresh environments such as CI
where your assets haven't changed and you haven't visited the page in a
browser.

#### Stopping everything:

```sh
# Stop the containers and remove a few Docker related resources associated to this project.
docker compose down
```

You can start things up again with `docker compose up` and unlike the first
time it should only take seconds.

### `.env`

This file is ignored from version control so it will never be commit. There's a
number of environment variables defined here that control certain options and
behavior of the application. Everything is documented there.

Feel free to add new variables as needed. This is where you should put all of
your secrets as well as configuration that might change depending on your
environment (specific dev boxes, CI, production, etc.).

### `run`

You can run `./run` to get a list of commands and each command has
documentation in the `run` file itself.

It's a shell script that has a number of functions defined to help you interact
with this project. It's basically a `Makefile` except with [less
limitations](https://nickjanetakis.com/blog/replacing-make-with-a-shell-script-for-running-your-projects-tasks).
For example as a shell script it allows us to pass any arguments to another
program.

This comes in handy to run various Docker commands because sometimes these
commands can be a bit long to type. Feel free to add as many convenience
functions as you want. This file's purpose is to make your experience better!

*If you get tired of typing `./run` you can always create a shell alias with
`alias run=./run` in your `~/.bash_aliases` or equivalent file. Then you'll be
able to run `run` instead of `./run`.*

## Start and setup the project:

### If you don't use Docker

Copy `.env.example` to `.env`, then execute `source .env`.  
Then run any rails command as usual, we can run the test `rails test` or the server `rails server`

### If you use Docker

Copy `.env.example` file to `.env` then run following command

```sh
docker compose up --build

# Then in a 2nd terminal once it's up and ready.
./run rails db:setup

./run test # to run the test
./run bundle:install # to install the dependencies
./run bundle:update # to update the dependencies
```

If you need to run with Citus:

```sh
docker compose -f docker-compose-citus.yml up --build
```

*If you get an error upping the project related to `RuntimeError: invalid
bytecode` then you have old `tmp/` files sitting around related to the old
project name, you can run `./run clean` to clear all temporary files and fix
the error.*

If you need to run ElasticAPM with Docker Compose, you can use the `elastic-apm` profile:

```sh
docker compose --profile elastic-apm up -d
```