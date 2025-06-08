#!/bin/bash

# Start services
service postgresql start
service redis-server start

# Output status
echo "PostgreSQL status: $(service postgresql status)"
echo "Redis status: $(service redis-server status)"

# Check Redis connection
echo "Testing Redis connection..."
if redis-cli ping | grep -q "PONG"; then
  echo "Redis is working properly!"
else
  echo "Redis connection failed!"
fi

# Return success
exit 0
