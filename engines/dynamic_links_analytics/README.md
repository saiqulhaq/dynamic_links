# Dynamic Links Analytics Engine

This document describes the implementation of the `dynamic_links_analytics` engine that consumes events from the `dynamic_links` engine and stores metrics in PostgreSQL with optimized indexing.

## Architecture Overview

The analytics engine follows a plugin-based architecture that:

- Subscribes to `link_clicked.dynamic_links` events published by the core dynamic_links engine
- Processes events asynchronously using ActiveJob/Sidekiq to avoid blocking redirects
- Stores analytics data in PostgreSQL with optimized JSONB indexing
- Leverages pg_stat_statements for query performance monitoring

## Implementation Details

### 1. Event Subscription (`lib/dynamic_links_analytics/engine.rb`)

The engine automatically subscribes to Rails instrumentation events when the application initializes:

```ruby
ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |_name, _started, _finished, _unique_id, payload|
  # Extract only serializable data for the job
  shortened_url = payload[:shortened_url]
  serializable_payload = payload.except(:shortened_url)

  # Add serializable data from the shortened_url object
  serializable_payload[:client_id] = shortened_url.client_id if shortened_url.respond_to?(:client_id)

  # Process the event asynchronously to avoid blocking the redirect
  DynamicLinksAnalytics::ClickEventProcessor.perform_later(serializable_payload)
end
```

### 2. Data Model (`app/models/dynamic_links_analytics/link_click.rb`)

The `LinkClick` model stores analytics data with:

- Basic click information (short_url, original_url, ip_address, clicked_at)
- Client identification (client_id)
- Flexible metadata storage using JSONB for:
  - UTM parameters (source, medium, campaign)
  - Browser and device information (including mobile detection)
  - Referrer data and domain extraction
  - Request details (method, path, query string)
  - Browser language detection
  - Geographic data (placeholder for IP-to-location mapping)
  - Processing timestamp

### 3. Database Schema with PostgreSQL Optimizations

The migration (`db/migrate/20250808000001_create_dynamic_links_analytics_link_clicks.rb`) creates:

#### Core Table Structure

```sql
CREATE TABLE dynamic_links_analytics_link_clicks (
  id BIGSERIAL PRIMARY KEY,
  short_url VARCHAR NOT NULL,
  original_url TEXT NOT NULL,
  client_id VARCHAR,
  ip_address INET NOT NULL,
  clicked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

#### Performance Indexes

**Basic Indexes:**

- `idx_link_clicks_short_url` - Fast lookups by short URL
- `idx_link_clicks_client_id` - Client-based analytics
- `idx_link_clicks_clicked_at` - Time-based queries
- `idx_link_clicks_ip_address` - Unique visitor tracking

**Composite Indexes:**

- `idx_link_clicks_short_url_clicked_at` - Performance analytics per link
- `idx_link_clicks_client_id_clicked_at` - Client performance over time
- `idx_link_clicks_short_url_ip` - Unique visitors per link

**JSONB Indexes:**

- `idx_link_clicks_metadata_gin` - General JSONB queries using GIN index
- `idx_link_clicks_utm_source` - UTM source queries
- `idx_link_clicks_utm_medium` - UTM medium queries
- `idx_link_clicks_utm_campaign` - UTM campaign queries
- `idx_link_clicks_referrer` - Referrer analysis
- `idx_link_clicks_user_agent` - Browser/device analysis

**Partial Indexes (for efficiency):**

- `idx_link_clicks_utm_source_not_null` - Only for non-null UTM sources
- `idx_link_clicks_utm_campaign_not_null` - Only for non-null UTM campaigns
- `idx_link_clicks_referrer_not_null` - Only for non-null referrers

#### PostgreSQL Extensions

- `pg_stat_statements` - Enabled for query performance monitoring

### 4. Asynchronous Processing (`app/jobs/dynamic_links_analytics/click_event_processor.rb`)

The processor:

- Extracts and validates click data from event payloads
- Enriches data with additional metadata (mobile detection, browser parsing, language extraction)
- Stores records in the database with comprehensive error handling and exponential backoff retries
- Logs processing for monitoring and debugging
- Queues jobs in the `:analytics` queue for organized processing

### 5. Analytics Service (`app/services/dynamic_links_analytics/analytics_service.rb`)

Provides optimized query methods for:

- Link-specific statistics (clicks, unique visitors, referrers, UTM breakdown)
- Client-level analytics (performance across multiple links)
- Global system statistics
- Real-time metrics (recent activity)
- Query performance monitoring via pg_stat_statements

## Key Features

### Performance Optimizations

1. **JSONB Indexing**: Efficient queries on metadata without rigid schema
2. **Partial Indexes**: Reduce index size by excluding null/empty values
3. **Composite Indexes**: Optimize common query patterns
4. **GIN Indexes**: Fast JSONB containment and key-existence queries
5. **pg_stat_statements**: Monitor and optimize query performance

### Analytics Capabilities

1. **Click Tracking**: Count total clicks per link
2. **Unique Visitors**: Track by IP address
3. **UTM Parameter Analysis**: Marketing campaign effectiveness
4. **Referrer Analysis**: Traffic source identification
5. **Device/Browser Detection**: Mobile vs desktop usage
6. **Time-based Analytics**: Daily, hourly patterns
7. **Geographic Tracking**: IP-to-location (extensible)

### Scalability Features

1. **Asynchronous Processing**: Non-blocking event handling
2. **Background Jobs**: Sidekiq integration for high throughput
3. **Efficient Indexes**: Fast queries even with large datasets
4. **Partitioning Ready**: Schema supports future table partitioning
5. **Performance Monitoring**: Built-in query performance tracking

## Usage Examples

### Basic Analytics Queries

```ruby
# Link statistics
stats = DynamicLinksAnalytics::AnalyticsService.link_statistics('abc123')
puts "Total clicks: #{stats[:total_clicks]}"
puts "Unique visitors: #{stats[:unique_visitors]}"

# Client analytics
client_stats = DynamicLinksAnalytics::AnalyticsService.client_statistics('client_123')

# Global system stats
global_stats = DynamicLinksAnalytics::AnalyticsService.global_statistics

# Real-time activity
real_time = DynamicLinksAnalytics::AnalyticsService.real_time_stats(5) # last 5 minutes
```

### Custom Queries

```ruby
# Top performing links
DynamicLinksAnalytics::LinkClick.group(:short_url)
  .order('count_all DESC')
  .limit(10)
  .count

# UTM campaign performance
DynamicLinksAnalytics::LinkClick.with_utm_campaign('summer_2024')
  .group("metadata ->> 'utm_source'")
  .count

# Recent mobile traffic
DynamicLinksAnalytics::LinkClick.where("metadata ->> 'is_mobile' = 'true'")
  .where(clicked_at: 24.hours.ago..Time.current)
  .count
```

## Integration

The analytics engine is automatically loaded when the main application starts:

1. Add to main `Gemfile`: `gem 'dynamic_links_analytics', path: 'engines/dynamic_links_analytics'`
2. Run migrations: `rails db:migrate`
3. Events are automatically consumed when the dynamic_links engine publishes them

**Note**: The `engines/dynamic_links_analytics/Gemfile` is intentionally empty as dependencies are managed through the gemspec file.

## Testing

Comprehensive test coverage includes:

- Model validations and scopes
- Event consumption integration tests
- Analytics query performance tests
- Rails instrumentation verification

Run tests with:

```bash
bin/rails test engines/dynamic_links_analytics/test/
```

## Performance Monitoring

Query performance can be monitored using:

```ruby
# Get query performance stats
stats = DynamicLinksAnalytics::AnalyticsService.query_performance_stats
stats.each do |query_stat|
  puts "Query: #{query_stat['query']}"
  puts "Calls: #{query_stat['calls']}"
  puts "Avg time: #{query_stat['mean_exec_time']}ms"
  puts "Hit ratio: #{query_stat['hit_percent']}%"
end
```

## Future Enhancements

1. **Table Partitioning**: Implement time-based partitioning for large datasets
2. **Data Retention**: Automated cleanup of old analytics data
3. **Geographic Analytics**: IP-to-location mapping integration
4. **Advanced Browser Detection**: Enhanced user agent parsing
5. **Real-time Dashboards**: WebSocket-based live analytics
6. **Data Export**: CSV/JSON export capabilities
7. **Aggregated Views**: Pre-computed analytics tables for faster reporting

## Production Considerations

1. **Background Job Processing**: Ensure Sidekiq is running for async processing
2. **Database Maintenance**: Regular VACUUM and ANALYZE on the analytics table
3. **Index Monitoring**: Monitor index usage and performance
4. **Data Growth**: Plan for storage growth and potential partitioning
5. **Query Optimization**: Use pg_stat_statements to identify slow queries
6. **Memory Usage**: Monitor JSONB index memory usage
7. **Backup Strategy**: Include analytics data in backup planning

This implementation provides a robust, scalable analytics solution that efficiently processes click events while maintaining excellent query performance through optimized PostgreSQL indexing strategies.
