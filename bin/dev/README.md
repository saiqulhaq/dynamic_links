# Development Scripts

This directory contains development and testing utility scripts for the Dynamic Links project.

## Analytics Testing Scripts

### `demo_analytics.rb`

Demonstrates and tests the analytics event consumption system.

**Usage:**

```bash
./bin/dev/demo_analytics.rb
```

**Purpose:**

- Simulates click events that would be published by the dynamic_links engine
- Tests the analytics processing pipeline
- Useful for development and debugging analytics functionality

### `test_seeded_analytics.rb`

Tests analytics using actual seeded database data.

**Usage:**

```bash
# First seed the database
bin/rails db:seed

# Then run the test
./bin/dev/test_seeded_analytics.rb
```

**Purpose:**

- Integration testing with real database data
- Verifies end-to-end analytics flow with seeded URLs
- Tests the complete click tracking pipeline

### `test_instrumentation.rb`

Tests the Rails instrumentation event system.

**Usage:**

```bash
./bin/dev/test_instrumentation.rb
```

**Purpose:**

- Verifies Rails ActiveSupport::Notifications event publishing
- Tests event subscription and processing
- Validates the event infrastructure

## Requirements

All scripts require:

- Rails environment loaded
- Database setup and migrated
- Analytics engine properly configured

## Notes

These scripts are for development and testing purposes only. They should not be used in production environments.
