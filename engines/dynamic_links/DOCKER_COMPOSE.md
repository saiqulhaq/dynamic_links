# Docker Compose Development Setup

This project uses Docker Compose for development to make it easy to set up a consistent development environment.

## Getting Started

1. Make sure you have Docker and Docker Compose installed on your machine.
2. Open the project in VS Code with the Remote - Containers extension installed.
3. VS Code will prompt you to reopen the project in a container. Click "Reopen in Container".
4. The container will be built and the project dependencies will be installed automatically.

## Available Container Services

- **app**: The main application container with Ruby 3.2
- **postgres**: PostgreSQL 15 database
- **redis**: Redis 7 for caching and background jobs

## Database Configuration

The database.yml is configured to connect to the PostgreSQL container using the following environment variables:

```yaml
POSTGRES_DB: dynamic_links
POSTGRES_USER: postgres
POSTGRES_PASSWORD: postgres
POSTGRES_HOST: postgres
POSTGRES_PORT: 5432
```

## Redis Configuration

Redis is available at `redis:6379` within the containers. You can configure your application to use it with:

```ruby
REDIS_URL=redis://redis:6379/1
```

## VS Code Tasks

Several VS Code tasks are available to make development easier:

- **Rails: Run Server**: Start the Rails server
- **Rails: Run Console**: Open a Rails console
- **Run Tests**: Run the test suite
- **Run RuboCop**: Run RuboCop for code linting
- **Rails: Migrate Database**: Run database migrations
- **Run Redis Server**: Start a Redis server (not needed with Docker Compose)
- **Run Sidekiq**: Start Sidekiq for background job processing
- **Docker Compose: Up**: Start all containers
- **Docker Compose: Down**: Stop all containers
- **Docker Compose: Logs**: View logs from all containers
- **Docker Compose: Rebuild**: Rebuild containers from scratch

You can access these tasks by pressing `F1` and typing "Tasks: Run Task".

## Troubleshooting

### PostgreSQL Connection Issues

If you're having trouble connecting to PostgreSQL, ensure the container is running:

```bash
docker-compose ps
```

You can check logs for any PostgreSQL errors:

```bash
docker-compose logs postgres
```

### Bundle Install Issues

If you're having issues with bundle install, you can run it manually inside the container:

```bash
docker-compose exec app bundle install
```

### Resetting the Database

To reset the database, run:

```bash
docker-compose exec app bash -c "cd test/dummy && bin/rails db:reset"
```
