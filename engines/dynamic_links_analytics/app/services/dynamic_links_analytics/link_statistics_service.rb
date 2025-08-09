module DynamicLinksAnalytics
  class LinkStatisticsService
    def self.call(short_url, date_range = nil)
      new(short_url, date_range).call
    end

    def initialize(short_url, date_range = nil)
      @short_url = short_url
      @date_range = date_range
    end

    def call
      {
        total_clicks: base_scope.count,
        unique_visitors: base_scope.distinct.count(:ip_address),
        top_referrers: top_referrers,
        utm_sources: utm_sources,
        daily_breakdown: AnalyticsHelpers::TimeBreakdownService.daily_clicks(base_scope),
        hourly_distribution: AnalyticsHelpers::TimeBreakdownService.hourly_distribution(base_scope),
        device_breakdown: AnalyticsHelpers::DeviceBreakdownService.call(base_scope)
      }
    end

    private

    attr_reader :short_url, :date_range

    def base_scope
      @base_scope ||= begin
        scope = LinkClick.for_short_url(short_url)
        scope = scope.in_date_range(date_range.begin, date_range.end) if date_range
        scope
      end
    end

    def top_referrers
      base_scope.joins('')
                .group("metadata ->> 'referrer'")
                .where.not("metadata ->> 'referrer'" => [nil, ''])
                .order('count_all DESC')
                .limit(10)
                .count
    end

    def utm_sources
      base_scope.group("metadata ->> 'utm_source'")
                .where.not("metadata ->> 'utm_source'" => [nil, ''])
                .order('count_all DESC')
                .count
    end
  end
end
