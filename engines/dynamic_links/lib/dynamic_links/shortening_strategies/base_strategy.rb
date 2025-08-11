# frozen_string_literal: true

module DynamicLinks
  module ShorteningStrategies
    class BaseStrategy
      MIN_LENGTH = 5

      BASE62_CHARS = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'.freeze

      def shorten(url)
        raise NotImplementedError, 'You must implement the shorten method'
      end

      # Ensures the generated short URL respects the maximum length configuration
      # @param short_url [String] The generated short URL
      # @return [String] The short URL truncated to the maximum allowed length
      def enforce_max_length(short_url)
        max_length = DynamicLinks.configuration.max_shortened_url_length
        return short_url if short_url.length <= max_length

        short_url[0...max_length]
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

        result = +'' # Use unary plus to create an unfrozen string
        while integer.positive?
          result.prepend(BASE62_CHARS[integer % 62])
          integer /= 62
        end
        result
      end
    end
  end
end
