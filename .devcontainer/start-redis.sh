#!/bin/bash
set -e

# This script is used to start Redis service within the dev container

# Start Redis service
service redis-server start

# Wait for Redis to start
until redis-cli ping > /dev/null 2>&1; do
  echo "Waiting for Redis to start..."
  sleep 1
done

echo "Redis started successfully."

# Keep the script running to keep the service running
tail -f /dev/null
