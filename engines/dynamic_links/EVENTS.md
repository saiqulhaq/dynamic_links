# Dynamic Links Engine Events

This document describes the Rails instrumentation events published by the Dynamic Links engine. These events can be consumed by other engines, particularly the analytics engine, to track and analyze link usage.

## Events

### `link_clicked.dynamic_links`

This event is triggered when a shortened link is accessed and redirected.

**When:** Published in `DynamicLinks::RedirectsController#show` after a valid shortened URL is found and before the redirect happens.

**Location:** `engines/dynamic_links/app/controllers/dynamic_links/redirects_controller.rb:50`

**Payload:**

```ruby
{
  shortened_url: ShortenedUrl,  # The ShortenedUrl model instance
  short_url: String,            # The short URL identifier (e.g., "abc123")
  original_url: String,         # The original destination URL
  user_agent: String,           # Browser user agent string
  referrer: String,             # HTTP referrer header (may be nil)
  ip: String,                   # Client IP address
  utm_source: String,           # UTM source parameter (may be nil)
  utm_medium: String,           # UTM medium parameter (may be nil)
  utm_campaign: String,         # UTM campaign parameter (may be nil)
  landing_page: String,         # The full requested URL including parameters
  request: ActionDispatch::Request  # The full Rails request object
}
```

**Example Usage:**

```ruby
# Subscribe to the event
ActiveSupport::Notifications.subscribe('link_clicked.dynamic_links') do |name, started, finished, unique_id, payload|
  # Handle the click event
  ShortenedUrl = payload[:shortened_url]
  puts "Link clicked: #{payload[:short_url]} -> #{payload[:original_url]}"
  
  # Track analytics
  AnalyticsService.track_click(
    short_url: payload[:short_url],
    original_url: payload[:original_url],
    user_agent: payload[:user_agent],
    ip: payload[:ip],
    referrer: payload[:referrer],
    utm_params: {
      source: payload[:utm_source],
      medium: payload[:utm_medium],
      campaign: payload[:utm_campaign]
    }
  )
end
```

## Implementation Notes

- Events are only published for successful redirects (when a valid shortened URL is found)
- Events are published before the actual redirect occurs
- The `request` object is included in the payload to provide access to additional request data if needed
- UTM parameters are extracted from query parameters and may be `nil`
- The `shortened_url` object provides access to additional data like `client_id`, `created_at`, etc.

## Analytics Engine Integration

The `DynamicLinksAnalytics` engine subscribes to these events to:
- Track visit counts
- Store analytics data
- Generate usage reports
- Provide metrics dashboards

See the `engines/dynamic_links_analytics` documentation for details on how these events are consumed.