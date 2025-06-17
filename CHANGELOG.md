# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.2.0] - 2025-06-17

- [#88](https://github.com/saiqulhaq/dynamic_links/pull/88)
  * New Feature: Added API method to expand shortened URLs via the `expand` endpoint
  * New Feature: Added fallback mode to redirect to Firebase host when short URL not found
  * Enhancement: Improved multi-tenant support in controllers
  * Enhancement: Changed default shortening strategy from MD5 to NanoID

- [#19](https://github.com/saiqulhaq/dynamic_links/pull/19)
  * New Feature: Added asynchronous URL shortening functionality, improving performance for large-scale operations.
  * Refactor: Updated DynamicLinks::Configuration class to accommodate new features and improve flexibility.
  * Test: Expanded test coverage to include new features and functionalities.
  * Documentation: Updated README with instructions on performance optimization and running unit tests.
  * Chore: Added benchmarking scripts to measure the performance of synchronous vs asynchronous URL shortening and different versions of `create_or_find` method.
- Custom domain per client
- Ruby API for URL shortening.
- Add CRC32, nanoid, Redis counter, and KGS strategies to shorten an URL.
- URL validation feature.
- Configuration option to enable/disable REST API.
- Redirection feature. [#14](https://github.com/saiqulhaq/dynamic_links/pull/14)
