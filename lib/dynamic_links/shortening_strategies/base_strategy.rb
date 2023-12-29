module DynamicLinks
  module ShorteningStrategies
    class BaseStrategy
      def shorten(url)
        raise NotImplementedError, "You must implement the shorten method"
      end
    end
  end
end

