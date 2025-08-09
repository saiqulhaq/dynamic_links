module DynamicLinksAnalytics
  module AnalyticsHelpers
    class BrowserStatisticsService
      def self.call(scope)
        new(scope).call
      end

      def initialize(scope)
        @scope = scope
      end

      def call
        user_agents = scope.where.not("metadata ->> 'user_agent'" => [nil, ''])
                           .pluck("metadata ->> 'user_agent'")

        browser_counts = user_agents.each_with_object(Hash.new(0)) do |user_agent, counts|
          browser_name = extract_browser_name(user_agent)
          counts[browser_name] += 1
        end

        browser_counts.sort_by { |_, count| -count }.to_h
      end

      private

      attr_reader :scope

      def extract_browser_name(user_agent)
        return 'Unknown' if user_agent.blank?

        case user_agent.downcase
        when /chrome/i
          'Chrome'
        when /firefox/i
          'Firefox'
        when /safari/i
          'Safari'
        when /edge/i
          'Edge'
        when /opera/i
          'Opera'
        else
          'Other'
        end
      end
    end
  end
end
