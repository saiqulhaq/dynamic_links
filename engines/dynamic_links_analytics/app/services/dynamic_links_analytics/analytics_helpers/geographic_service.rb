module DynamicLinksAnalytics
  module AnalyticsHelpers
    class GeographicService
      def self.call(scope)
        scope.group("metadata ->> 'country_code'")
             .where.not("metadata ->> 'country_code'" => [nil, ''])
             .order('count_all DESC')
             .count
      end
    end
  end
end
