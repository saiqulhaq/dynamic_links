#!/bin/bash
set -e

echo "Setting up development environment..."

# Define variables
PROJECT_ROOT="/workspaces/dynamic_links"
DUMMY_APP="${PROJECT_ROOT}/test/dummy"
CONFIG_DIR="${DUMMY_APP}/config"

# Ensure required services are running
check_service() {
  local service_name="$1"
  echo "Checking ${service_name} service status..."

  if service "${service_name}" status > /dev/null 2>&1; then
    echo "✅ ${service_name} is running"
  else
    echo "⚠️ ${service_name} is not running, attempting to start..."
    service "${service_name}" start
    sleep 2
    if service "${service_name}" status > /dev/null 2>&1; then
      echo "✅ ${service_name} started successfully"
    else
      echo "❌ Failed to start ${service_name}. Setup may fail."
      return 1
    fi
  fi
  return 0
}

# Check if PostgreSQL service is running
check_service postgresql
postgres_running=$?

# Check if Redis service is running
check_service redis-server
redis_running=$?

# Install required gems
echo "Installing Ruby gems..."
bundle install

# Copy database configuration if it doesn't exist
if [ ! -f "${CONFIG_DIR}/database.yml" ]; then
  mkdir -p "${CONFIG_DIR}"
  cp "${PROJECT_ROOT}/.devcontainer/database.yml" "${CONFIG_DIR}/"
  echo "Database configuration copied."
fi

# Create .env file for development if it doesn't exist
if [ ! -f "${DUMMY_APP}/.env" ]; then
  cat > "${DUMMY_APP}/.env" << EOF
RAILS_ENV=development
DATABASE_URL=postgres://vscode:vscode@localhost/dynamic_links_development
REDIS_URL=redis://localhost:6379/1
EOF
  echo "Environment configuration created."
fi

# Set up the database if PostgreSQL is running
if [ $postgres_running -eq 0 ]; then
  echo "Setting up the database..."
  cd "${DUMMY_APP}"

  # Check if database exists
  if psql -lqt | grep -q dynamic_links_development; then
    echo "Database already exists, running migrations..."
    bin/rails db:migrate
  else
    echo "Creating database and loading schema..."
    bin/rails db:setup || {
      echo "❌ Database setup failed. You can manually create it with these commands:"
      echo "   cd ${DUMMY_APP}"
      echo "   bin/rails db:create"
      echo "   bin/rails db:schema:load"
      echo "   bin/rails db:seed  # If you have seed data"
    }
  fi
else
  echo "❌ PostgreSQL is not running. Database setup skipped."
fi

# Verify Redis connection if Redis is running
if [ $redis_running -eq 0 ]; then
  echo "Verifying Redis connection..."
  if redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis connection verified"
  else
    echo "❌ Redis connection failed, but service appears to be running."
    echo "   This might cause issues with Redis-dependent features."
  fi
else
  echo "❌ Redis is not running. Redis-dependent features may not work."
fi

# Install JS dependencies if package.json exists
if [ -f "${DUMMY_APP}/package.json" ]; then
  echo "Installing JavaScript dependencies..."
  cd "${DUMMY_APP}" && yarn install
fi

# Set up Solargraph for code intelligence (only if not already installed)
if ! gem list | grep -q "^solargraph "; then
  echo "Installing Solargraph for Ruby code intelligence..."
  gem install solargraph
else
  echo "✅ Solargraph is already installed"
fi

# Initialize Solargraph bundle
echo "Initializing Solargraph bundle..."
cd "${PROJECT_ROOT}" && solargraph bundle

echo "✅ Setup completed successfully!"
echo "You can now run 'cd test/dummy && bin/rails server' to start the development server."
echo "Or use the VS Code tasks from the Command Palette (F1 > Tasks: Run Task)."
