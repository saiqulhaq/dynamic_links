module DynamicLinksAnalytics
  module AnalyticsHelpers
    class TopLinksService
      def self.call(scope, limit = 20)
        scope.group(:short_url, :original_url)
             .order('count_all DESC')
             .limit(limit)
             .count
             .map do |(short_url, original_url), count|
          { short_url: short_url, original_url: original_url,
            clicks: count }
        end
      end
    end
  end
end
