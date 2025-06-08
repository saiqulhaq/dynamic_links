#!/bin/bash
set -e

echo "Setting up development environment..."

# Install required gems
echo "Installing Ruby gems..."
bundle install

# Copy database configuration if it doesn't exist
if [ ! -f /workspaces/dynamic_links/test/dummy/config/database.yml ]; then
  mkdir -p /workspaces/dynamic_links/test/dummy/config
  cp /workspaces/dynamic_links/.devcontainer/database.yml /workspaces/dynamic_links/test/dummy/config/
  echo "Database configuration copied."
fi

# Create .env file for development if it doesn't exist
if [ ! -f /workspaces/dynamic_links/test/dummy/.env ]; then
  cat > /workspaces/dynamic_links/test/dummy/.env << EOF
RAILS_ENV=development
DATABASE_URL=postgres://vscode:vscode@localhost/dynamic_links_development
REDIS_URL=redis://localhost:6379/1
EOF
  echo "Environment configuration created."
fi

# Set up the database
echo "Setting up the database..."
cd /workspaces/dynamic_links/test/dummy
bin/rails db:setup || echo "Database setup failed, you may need to create it manually"

# Ensure Redis is running
echo "Checking Redis status..."
service redis-server status || service redis-server start
redis-cli ping || echo "Redis may not be running properly"

# Install JS dependencies if package.json exists
if [ -f /workspaces/dynamic_links/test/dummy/package.json ]; then
  echo "Installing JavaScript dependencies..."
  cd /workspaces/dynamic_links/test/dummy && yarn install
fi

# Set up Solargraph for code intelligence
echo "Setting up Solargraph for Ruby code intelligence..."
gem install solargraph
solargraph bundle

echo "Setup completed successfully. You can now run 'cd test/dummy && bin/rails server' to start the development server."
