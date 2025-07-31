# frozen_string_literal: true

module DynamicLinks
  module ShorteningStrategies
    class BaseStrategy
      MIN_LENGTH = 5

      BASE62_CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

      def shorten(url)
        raise NotImplementedError, 'You must implement the shorten method'
      end

      # Determines if the strategy always generates a new shortened URL
      # @return [Boolean]
      def always_growing?
        false # Default behavior is not to always grow
      end

      private

      # Convert an integer into a Base62 string
      def base62_encode(integer)
        return '0' if integer.zero?

        result = ''
        while integer.positive?
          result.prepend(BASE62_CHARS[integer % 62])
          integer /= 62
        end
        result
      end
    end
  end
end
