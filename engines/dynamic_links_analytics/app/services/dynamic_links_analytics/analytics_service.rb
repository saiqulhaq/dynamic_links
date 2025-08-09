module DynamicLinksAnalytics
  class AnalyticsService
    # This service provides optimized analytics queries using PostgreSQL features
    # Leverages JSONB indexing and pg_stat_statements for performance monitoring

    def self.link_statistics(short_url, date_range = nil)
      base_scope = LinkClick.for_short_url(short_url)
      base_scope = base_scope.in_date_range(date_range.begin, date_range.end) if date_range

      {
        total_clicks: base_scope.count,
        unique_visitors: base_scope.distinct.count(:ip_address),
        top_referrers: base_scope.joins('').group("metadata ->> 'referrer'")
                                 .where.not("metadata ->> 'referrer'" => [nil, ''])
                                 .order('count_all DESC')
                                 .limit(10)
                                 .count,
        utm_sources: base_scope.group("metadata ->> 'utm_source'")
                               .where.not("metadata ->> 'utm_source'" => [nil, ''])
                               .order('count_all DESC')
                               .count,
        daily_breakdown: daily_clicks_breakdown(base_scope),
        hourly_distribution: hourly_distribution(base_scope),
        device_breakdown: device_breakdown(base_scope)
      }
    end

    def self.client_statistics(client_id, date_range = nil)
      base_scope = LinkClick.for_client(client_id)
      base_scope = base_scope.in_date_range(date_range.begin, date_range.end) if date_range

      {
        total_clicks: base_scope.count,
        unique_visitors: base_scope.distinct.count(:ip_address),
        unique_links: base_scope.distinct.count(:short_url),
        top_performing_links: top_performing_links(base_scope),
        utm_campaign_performance: utm_campaign_performance(base_scope),
        traffic_sources: traffic_sources_breakdown(base_scope)
      }
    end

    def self.global_statistics(date_range = nil)
      base_scope = LinkClick.all
      base_scope = base_scope.in_date_range(date_range.begin, date_range.end) if date_range

      {
        total_clicks: base_scope.count,
        unique_visitors: base_scope.distinct.count(:ip_address),
        unique_links: base_scope.distinct.count(:short_url),
        active_clients: base_scope.distinct.count(:client_id),
        top_links: global_top_links(base_scope),
        geographic_distribution: geographic_distribution(base_scope),
        browser_stats: browser_statistics(base_scope)
      }
    end

    # Performance monitoring using pg_stat_statements
    def self.query_performance_stats
      return {} unless pg_stat_statements_available?

      ActiveRecord::Base.connection.execute(<<~SQL).to_a
        SELECT
          query,
          calls,
          total_exec_time,
          mean_exec_time,
          stddev_exec_time,
          rows,
          100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
        FROM pg_stat_statements
        WHERE query LIKE '%dynamic_links_analytics_link_clicks%'
        ORDER BY total_exec_time DESC
        LIMIT 20;
      SQL
    end

    # Real-time analytics with optimized queries
    def self.real_time_stats(minutes = 5)
      recent_scope = LinkClick.where(clicked_at: minutes.minutes.ago..Time.current)

      {
        recent_clicks: recent_scope.count,
        clicks_per_minute: recent_scope.group("DATE_TRUNC('minute', clicked_at)")
                                       .order('date_trunc_minute_clicked_at DESC')
                                       .limit(minutes)
                                       .count,
        active_links: recent_scope.distinct.count(:short_url),
        top_active_links: recent_scope.group(:short_url)
                                      .order('count_all DESC')
                                      .limit(5)
                                      .count
      }
    end

    private

    def self.daily_clicks_breakdown(scope, days = 30)
      scope.where(clicked_at: days.days.ago..Time.current)
           .group('DATE(clicked_at)')
           .order('date_clicked_at')
           .count
    end

    def self.hourly_distribution(scope)
      scope.group('EXTRACT(hour FROM clicked_at)')
           .order('extract_hour_from_clicked_at')
           .count
    end

    def self.device_breakdown(scope)
      mobile_count = scope.where("metadata ->> 'is_mobile' = 'true'").count
      desktop_count = scope.where("metadata ->> 'is_mobile' = 'false'").count
      unknown_count = scope.where("metadata ->> 'is_mobile' IS NULL").count

      {
        mobile: mobile_count,
        desktop: desktop_count,
        unknown: unknown_count
      }
    end

    def self.top_performing_links(scope, limit = 10)
      scope.group(:short_url)
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def self.utm_campaign_performance(scope)
      scope.where.not("metadata ->> 'utm_campaign'" => [nil, ''])
           .group("metadata ->> 'utm_campaign'")
           .order('count_all DESC')
           .count
    end

    def self.traffic_sources_breakdown(scope)
      # Categorize traffic sources
      direct = scope.where("metadata ->> 'referrer' IS NULL OR metadata ->> 'referrer' = ''").count
      search_engines = scope.where("metadata ->> 'referrer' ILIKE '%google%' OR metadata ->> 'referrer' ILIKE '%bing%' OR metadata ->> 'referrer' ILIKE '%yahoo%'").count
      social_media = scope.where("metadata ->> 'referrer' ILIKE '%facebook%' OR metadata ->> 'referrer' ILIKE '%twitter%' OR metadata ->> 'referrer' ILIKE '%linkedin%'").count

      {
        direct: direct,
        search_engines: search_engines,
        social_media: social_media,
        other: scope.count - direct - search_engines - social_media
      }
    end

    def self.global_top_links(scope, limit = 20)
      scope.group(:short_url)
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def self.geographic_distribution(scope)
      scope.where.not("metadata ->> 'country_code'" => [nil, ''])
           .group("metadata ->> 'country_code'")
           .order('count_all DESC')
           .count
    end

    def self.browser_statistics(scope)
      # Extract browser information from user agent
      browsers = {}

      scope.where.not("metadata ->> 'user_agent'" => [nil, '']).find_each do |click|
        user_agent = click.metadata['user_agent']
        browser = extract_browser_name(user_agent)
        browsers[browser] = (browsers[browser] || 0) + 1
      end

      browsers.sort_by { |_browser, count| -count }.to_h
    end

    def self.extract_browser_name(user_agent)
      return 'Unknown' if user_agent.blank?

      case user_agent
      when /Chrome/i
        'Chrome'
      when /Firefox/i
        'Firefox'
      when /Safari/i
        'Safari'
      when /Edge/i
        'Edge'
      when /Opera/i
        'Opera'
      else
        'Other'
      end
    end

    def self.pg_stat_statements_available?
      ActiveRecord::Base.connection.execute(
        "SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'"
      ).any?
    rescue StandardError
      false
    end
  end
end
