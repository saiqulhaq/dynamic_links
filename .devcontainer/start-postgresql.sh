#!/bin/bash
set -e

# This script is used to start PostgreSQL service within the dev container

# Start PostgreSQL service
service postgresql start

# Wait for PostgreSQL to start
until pg_isready > /dev/null 2>&1; do
  echo "Waiting for PostgreSQL to start..."
  sleep 1
done

# Create PostgreSQL user and database if they don't exist
if ! psql -U postgres -c "SELECT 1 FROM pg_roles WHERE rolname='vscode'" > /dev/null 2>&1; then
  psql -U postgres -c "CREATE USER vscode WITH SUPERUSER PASSWORD 'vscode';"
fi

echo "PostgreSQL started and configured successfully."

# Keep the script running to keep the service running
tail -f /dev/null
