# Changelog

All notable changes to the Dynamic Links Analytics Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-08-08

### Added
- **Core Analytics Engine**: Initial implementation of the Dynamic Links Analytics Engine
- **Event Processing**: ClickEventProcessor job for asynchronous handling of link click events
- **Data Model**: LinkClick model with comprehensive click tracking and metadata storage
- **Database Schema**: PostgreSQL-optimized table with advanced indexing strategies:
  - Basic indexes for short_url, client_id, clicked_at, and ip_address
  - Composite indexes for performance analytics and unique visitor tracking
  - JSONB GIN indexes for efficient metadata queries
  - Partial indexes for UTM parameters and referrer data
- **Analytics Service**: Comprehensive analytics querying with optimized methods for:
  - Link-specific statistics (clicks, unique visitors, referrers, UTM breakdown)
  - Client-level analytics across multiple links
  - Global system statistics and real-time metrics
  - Query performance monitoring via pg_stat_statements
- **Event Subscription**: Automatic subscription to `link_clicked.dynamic_links` events
- **Metadata Tracking**: Comprehensive metadata capture including:
  - UTM parameters (source, medium, campaign, term, content)
  - Browser and device detection (mobile, desktop)
  - Referrer domain extraction and analysis
  - Request headers and user agent parsing
- **Performance Optimizations**:
  - Asynchronous event processing with ActiveJob/Sidekiq
  - PostgreSQL extensions (pg_stat_statements) for monitoring
  - Efficient JSONB indexing for flexible metadata queries
- **Testing Suite**: Complete test coverage including:
  - Model validations and scopes
  - Event consumption integration tests
  - Analytics query performance verification
- **Documentation**: Comprehensive README with architecture overview, usage examples, and production considerations

### Technical Details
- PostgreSQL database with optimized indexing for high-performance analytics
- Rails engine architecture for modular integration
- Sidekiq integration for background job processing
- JSONB storage for flexible metadata without rigid schema constraints
- Real-time analytics capabilities with configurable time windows
- Built-in query performance monitoring and optimization tools

[0.1.0]: https://github.com/saiqulhaq/dynamic_links/releases/tag/v0.1.0