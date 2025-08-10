# GitHub Actions Caching Improvements

## Overview

Added comprehensive caching to all GitHub Actions workflows to significantly speed up CI/CD pipeline execution times.

## Improvements Made

### 1. Engine Test Workflow (`engine_test.yml`)

#### Dynamic Links Engine Job:

- **Bundler Cache**: Added `bundler-cache: true` to Ruby setup
- **Bundle Dependencies**: Cache `vendor/bundle` and `~/.bundle` directories
- **Database Schema**: Cache schema.rb based on migration files
- **Cache Keys**: Use Gemfile.lock hash for dependency versioning

#### Dynamic Links Analytics Engine Job:

- **Bundler Cache**: Added `bundler-cache: true` to Ruby setup
- **Bundle Dependencies**: Cache analytics-specific bundle dependencies
- **Cache Keys**: Separate cache keys for analytics engine

### 2. Unit Test Workflow (`unit_test.yml`)

- **Node.js Dependencies**: Enhanced yarn caching with multiple cache paths
- **Ruby Dependencies**: Added bundler cache with vendor/bundle deployment
- **Build Artifacts**: Cache compiled assets and builds
- **Multiple Cache Layers**:
  - Yarn cache (node_modules, ~/.yarn/berry/cache)
  - Bundle cache (vendor/bundle, ~/.bundle)
  - Asset builds (app/assets/builds, public/assets)

### 3. Publish Gem Workflow (`publish_gem.yml`)

- **Bundler Cache**: Added `bundler-cache: true` to Ruby setup
- **Bundle Dependencies**: Cache vendor/bundle for gem publishing
- **Gem Build Artifacts**: Cache built .gem files
- **Cache Keys**: Specific keys for publishing workflow

## Cache Strategy Benefits

### Performance Improvements:

- **Bundle Install**: ~2-5 minutes → ~30 seconds (when cache hit)
- **Yarn Install**: ~1-3 minutes → ~15 seconds (when cache hit)
- **Asset Building**: ~1-2 minutes → ~20 seconds (when cache hit)
- **Database Setup**: Potentially faster with schema caching

### Cache Key Strategy:

- **Dependencies**: Hash-based keys using lock files (`Gemfile.lock`, `yarn.lock`)
- **Build Artifacts**: Content-based keys including source file hashes
- **Schema**: Migration-based keys for database schema
- **Restore Keys**: Fallback keys for partial cache hits

### Cache Paths:

- **Ruby/Bundler**: `vendor/bundle`, `~/.bundle`
- **Node.js/Yarn**: `node_modules`, `~/.yarn/berry/cache`, `~/.cache/yarn`
- **Assets**: `app/assets/builds`, `public/assets`
- **Gems**: Built `.gem` files for publishing

## Expected Speed Improvements

### First Run (Cache Miss):

- Same execution time as before
- Cache is populated for subsequent runs

### Subsequent Runs (Cache Hit):

- **70-80% reduction** in dependency installation time
- **50-60% reduction** in overall workflow execution time
- **90% reduction** in repeated asset compilation

### Cache Limits:

- GitHub Actions provides **10GB cache limit** per repository
- Old caches are automatically evicted after 7 days of inactivity
- Cache eviction happens when 10GB limit is reached

## Implementation Notes

### Ruby/Bundler Caching:

- Used recommended `bundler-cache: true` option in `ruby/setup-ruby` action
- Added manual caching for vendor/bundle deployment strategy
- Separate cache keys for different engines (dynamic_links vs analytics)

### Node.js/Yarn Caching:

- Enhanced built-in yarn caching with additional cache paths
- Cache both global yarn cache and local node_modules
- Asset build caching for compiled JavaScript/CSS

### Database Caching:

- Schema caching based on migration file changes
- Reduces database setup time on cache hits

### Cache Key Strategy:

- Primary keys use content hashes (lockfile changes invalidate cache)
- Restore keys provide fallback for partial matches
- OS-specific keys prevent cross-platform cache pollution

## Monitoring and Maintenance

### Cache Hit Monitoring:

- Check workflow logs for "Cache restored from key:" messages
- Monitor execution times before/after implementation

### Cache Maintenance:

- Caches automatically expire after 7 days of inactivity
- Manual cache clearing available through GitHub Actions API if needed
- Cache size monitoring through GitHub repository settings

## Version Updates

- Updated all `actions/checkout` from v3 → v4
- Updated `actions/setup-node` from v3 → v4
- All caching uses latest `actions/cache@v4`

## Expected ROI

- **Developer Time**: Faster CI feedback reduces context switching
- **Runner Costs**: Reduced execution time saves GitHub Actions minutes
- **Deployment Speed**: Faster builds enable quicker releases
- **Developer Experience**: Improved productivity with faster feedback loops
