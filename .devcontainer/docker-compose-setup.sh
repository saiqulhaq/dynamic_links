#!/bin/bash
# This script sets up environment configurations for the dummy app with Docker Compose

set -e

echo "Setting up development environment with Docker Compose..."

PROJECT_ROOT="/workspaces/dynamic_links"
DUMMY_APP="${PROJECT_ROOT}/test/dummy"
CONFIG_DIR="${DUMMY_APP}/config"
ENV_FILE="${DUMMY_APP}/.env"

# Create .env file for development with all the necessary environment variables
cat > "${ENV_FILE}" << EOF
RAILS_ENV=development

# PostgreSQL configuration
POSTGRES_DB=dynamic_links
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
DATABASE_URL=postgres://postgres:postgres@postgres:5432/dynamic_links_development

# Redis configuration
REDIS_URL=redis://redis:6379/1
EOF

echo "Environment configuration created at ${ENV_FILE}"

# Ensure the correct database.yml exists
if [ ! -f "${CONFIG_DIR}/database.yml" ] || ! grep -q "POSTGRES_HOST" "${CONFIG_DIR}/database.yml"; then
  echo "Configuring database.yml with Docker Compose settings..."

  mkdir -p "${CONFIG_DIR}"
  cat > "${CONFIG_DIR}/database.yml" << EOF
default: &default
  adapter: postgresql
  encoding: unicode
  database: "<%= ENV.fetch("POSTGRES_DB") { "dynamic_links" } %>"
  username: "<%= ENV.fetch("POSTGRES_USER") { "postgres" } %>"
  password: "<%= ENV.fetch("POSTGRES_PASSWORD") { "postgres" } %>"
  host: "<%= ENV.fetch("POSTGRES_HOST") { "postgres" } %>"
  port: "<%= ENV.fetch("POSTGRES_PORT") { 5432 } %>"
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: <%= ENV.fetch("POSTGRES_DB") { "dynamic_links" } %>_development

test:
  <<: *default
  database: <%= ENV.fetch("POSTGRES_DB") { "dynamic_links" } %>_test

production:
  <<: *default
  database: <%= ENV.fetch("POSTGRES_DB") { "dynamic_links" } %>_production
EOF
  echo "Database configuration updated for Docker Compose"
fi

# Verify connectivity to services
echo "Checking connectivity to PostgreSQL..."
timeout 5 bash -c 'until pg_isready -h postgres -p 5432 -U postgres; do sleep 1; done' 2>/dev/null &&
  echo "✅ PostgreSQL is accessible" ||
  echo "⚠️ PostgreSQL is not yet available. It might still be starting up."

echo "Checking connectivity to Redis..."
timeout 5 bash -c 'until redis-cli -h redis ping; do sleep 1; done' 2>/dev/null &&
  echo "✅ Redis is accessible" ||
  echo "⚠️ Redis is not yet available. It might still be starting up."

echo "Docker Compose environment setup complete!"
