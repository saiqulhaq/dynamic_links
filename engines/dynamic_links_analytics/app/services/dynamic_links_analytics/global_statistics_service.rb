module DynamicLinksAnalytics
  class GlobalStatisticsService
    def self.call(date_range = nil)
      new(date_range).call
    end

    def initialize(date_range = nil)
      @date_range = date_range
    end

    def call
      {
        total_clicks: base_scope.count,
        unique_visitors: base_scope.distinct.count(:ip_address),
        unique_links: base_scope.distinct.count(:short_url),
        active_clients: base_scope.distinct.count(:client_id),
        top_links: AnalyticsHelpers::TopLinksService.call(base_scope),
        geographic_distribution: AnalyticsHelpers::GeographicService.call(base_scope),
        browser_statistics: AnalyticsHelpers::BrowserStatisticsService.call(base_scope)
      }
    end

    private

    attr_reader :date_range

    def base_scope
      @base_scope ||= begin
        scope = LinkClick.all
        scope = scope.in_date_range(date_range.begin, date_range.end) if date_range
        scope
      end
    end
  end
end
