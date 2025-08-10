# frozen_string_literal: true

module DynamicLinksAnalytics
  class AnalyticsService
    # Legacy service class that delegates to specialized service classes
    # This maintains backward compatibility while providing better separation of concerns

    def self.link_statistics(short_url, date_range = nil)
      LinkStatisticsService.call(short_url, date_range)
    end

    def self.client_statistics(client_id, date_range = nil)
      ClientStatisticsService.call(client_id, date_range)
    end

    def self.global_statistics(date_range = nil)
      GlobalStatisticsService.call(date_range)
    end

    def self.query_performance_stats
      PerformanceStatsService.call
    end

    def self.real_time_stats(minutes = 5)
      RealtimeStatsService.call(minutes)
    end

    # Helper methods for backward compatibility
    def self.daily_clicks_breakdown(scope, days = 30)
      AnalyticsHelpers::TimeBreakdownService.daily_clicks(scope, days)
    end

    def self.hourly_distribution(scope)
      AnalyticsHelpers::TimeBreakdownService.hourly_distribution(scope)
    end

    def self.device_breakdown(scope)
      AnalyticsHelpers::DeviceBreakdownService.call(scope)
    end

    def self.top_performing_links(scope, limit = 10)
      scope.group(:short_url)
           .order('count_all DESC')
           .limit(limit)
           .count
    end

    def self.utm_campaign_performance(scope)
      scope.group("metadata ->> 'utm_campaign'")
           .where.not("metadata ->> 'utm_campaign'" => [nil, ''])
           .order('count_all DESC')
           .count
    end

    def self.traffic_sources_breakdown(scope)
      scope.joins('')
           .group("COALESCE(metadata ->> 'utm_source', metadata ->> 'referrer', 'direct')")
           .order('count_all DESC')
           .count
    end

    def self.global_top_links(scope, limit = 20)
      AnalyticsHelpers::TopLinksService.call(scope, limit)
    end

    def self.geographic_distribution(scope)
      AnalyticsHelpers::GeographicService.call(scope)
    end

    def self.browser_statistics(scope)
      AnalyticsHelpers::BrowserStatisticsService.call(scope)
    end

    def self.extract_browser_name(user_agent)
      AnalyticsHelpers::BrowserStatisticsService.new(LinkClick.none).send(:extract_browser_name, user_agent)
    end

    def self.pg_stat_statements_available?
      PerformanceStatsService.new.send(:pg_stat_statements_available?)
    end
  end
end
