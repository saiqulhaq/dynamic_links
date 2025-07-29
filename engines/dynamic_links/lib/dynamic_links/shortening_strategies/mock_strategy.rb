module DynamicLinks
  module ShorteningStrategies
    class MockStrategy < BaseStrategy
      def shorten(url)
        url
      end
    end
  end
end

