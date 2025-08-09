module DynamicLinksAnalytics
  module AnalyticsHelpers
    class TimeBreakdownService
      def self.daily_clicks(scope, days = 30)
        scope.where(clicked_at: days.days.ago..Time.current)
             .group('DATE(clicked_at)')
             .order('date_clicked_at DESC')
             .count
      end

      def self.hourly_distribution(scope)
        scope.group('EXTRACT(hour FROM clicked_at)')
             .order('extract_hour_from_clicked_at')
             .count
      end
    end
  end
end
