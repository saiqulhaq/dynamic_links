#!/bin/bash
set -e

echo "Checking Ruby version consistency..."

# Get the Ruby version from the development container
CONTAINER_RUBY_VERSION=$(ruby -e "puts RUBY_VERSION")
echo "Container Ruby version: $CONTAINER_RUBY_VERSION"

# Check RuboCop configuration
RUBOCOP_RUBY_VERSION=$(grep "TargetRubyVersion" .rubocop.yml | sed 's/.*: //')
echo "RuboCop target Ruby version: $RUBOCOP_RUBY_VERSION"

if [[ "$CONTAINER_RUBY_VERSION" == "$RUBOCOP_RUBY_VERSION"* ]]; then
  echo "✅ RuboCop target Ruby version matches container version"
else
  echo "❌ RuboCop target Ruby version ($RUBOCOP_RUBY_VERSION) does not match container version ($CONTAINER_RUBY_VERSION)"
  echo "Consider updating .rubocop.yml to match the container Ruby version."
fi

# Check gemspec Ruby version requirement
if [ -f "dynamic_links.gemspec" ]; then
  GEMSPEC_RUBY_REQ=$(grep "required_ruby_version" dynamic_links.gemspec || echo "Not specified")
  echo "Gemspec Ruby requirement: $GEMSPEC_RUBY_REQ"
fi

# Check for any version constraints in the Gemfile
GEMFILE_RUBY_VERSION=$(grep "ruby " Gemfile || echo "Not specified")
echo "Gemfile Ruby version: $GEMFILE_RUBY_VERSION"

echo "Ruby version check completed"
