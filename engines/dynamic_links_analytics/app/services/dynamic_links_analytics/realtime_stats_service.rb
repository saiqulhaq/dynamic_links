module DynamicLinksAnalytics
  class RealtimeStatsService
    def self.call(minutes = 5)
      new(minutes).call
    end

    def initialize(minutes = 5)
      @minutes = minutes
    end

    def call
      {
        recent_clicks: recent_scope.count,
        active_links: recent_scope.distinct.count(:short_url),
        top_active_links: top_active_links,
        clicks_per_minute: clicks_per_minute
      }
    end

    private

    attr_reader :minutes

    def recent_scope
      @recent_scope ||= LinkClick.where(clicked_at: minutes.minutes.ago..Time.current)
    end

    def top_active_links(limit = 5)
      recent_scope.group(:short_url)
                  .order('count_all DESC')
                  .limit(limit)
                  .count
    end

    def clicks_per_minute
      recent_scope.group("DATE_TRUNC('minute', clicked_at)")
                  .order('date_trunc_minute_clicked_at DESC')
                  .count
    end
  end
end
