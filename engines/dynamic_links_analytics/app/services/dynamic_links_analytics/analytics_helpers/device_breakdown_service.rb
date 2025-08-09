module DynamicLinksAnalytics
  module AnalyticsHelpers
    class DeviceBreakdownService
      def self.call(scope)
        new(scope).call
      end

      def initialize(scope)
        @scope = scope
      end

      def call
        {
          mobile: mobile_count,
          desktop: desktop_count,
          tablet: tablet_count,
          unknown: unknown_count
        }
      end

      private

      attr_reader :scope

      def mobile_count
        scope.where("metadata ->> 'is_mobile' = 'true'").count
      end

      def desktop_count
        scope.where("metadata ->> 'is_mobile' = 'false'")
             .where.not("metadata ->> 'user_agent' ILIKE ?", '%tablet%')
             .count
      end

      def tablet_count
        scope.where("metadata ->> 'user_agent' ILIKE ?", '%tablet%').count
      end

      def unknown_count
        scope.where("metadata ->> 'is_mobile' IS NULL OR metadata ->> 'user_agent' IS NULL").count
      end
    end
  end
end
