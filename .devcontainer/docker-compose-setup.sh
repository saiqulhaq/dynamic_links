#!/bin/bash
# This script sets up environment configurations for the dummy app with Docker Compose

set -e

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
