module DynamicLinksAnalytics
  class ClientStatisticsService
    def self.call(client_id, date_range = nil)
      new(client_id, date_range).call
    end

    def initialize(client_id, date_range = nil)
      @client_id = client_id
      @date_range = date_range
    end

    def call
      {
        total_clicks: base_scope.count,
        unique_visitors: base_scope.distinct.count(:ip_address),
        unique_links: base_scope.distinct.count(:short_url),
        top_performing_links: top_performing_links,
        utm_campaign_performance: utm_campaign_performance,
        traffic_sources: traffic_sources_breakdown
      }
    end

    private

    attr_reader :client_id, :date_range

    def base_scope
      @base_scope ||= begin
        scope = LinkClick.for_client(client_id)
        scope = scope.in_date_range(date_range.begin, date_range.end) if date_range
        scope
      end
    end

    def top_performing_links(limit = 10)
      base_scope.group(:short_url)
                .order('count_all DESC')
                .limit(limit)
                .count
    end

    def utm_campaign_performance
      base_scope.group("metadata ->> 'utm_campaign'")
                .where.not("metadata ->> 'utm_campaign'" => [nil, ''])
                .order('count_all DESC')
                .count
    end

    def traffic_sources_breakdown
      base_scope.joins('')
                .group("COALESCE(metadata ->> 'utm_source', metadata ->> 'referrer', 'direct')")
                .order('count_all DESC')
                .count
    end
  end
end
