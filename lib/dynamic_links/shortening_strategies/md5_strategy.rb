module DynamicLinks
  module ShorteningStrategies
    class MD5Strategy < BaseStrategy
      MIN_LENGTH = 5

      BASE62_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze

      # Shortens the given URL using an MD5 hash
      # @param url [String] The URL to shorten
      # @param min_length [Integer] The minimum length of the short URL
      def shorten(url, min_length: MIN_LENGTH)
        # Create an MD5 hash of the URL
        hashed_url = Digest::MD5.hexdigest(url)

        # Convert a portion of the MD5 hash into a Base62 string
        short_url = base62_encode(hashed_url[0...10].to_i(16))

        # Ensure the short URL is at least #{min_length} characters long
        short_url.ljust(min_length, '0')
      end

      private

      # Convert an integer into a Base62 string
      def base62_encode(integer)
        return '0' if integer == 0

        result = ''
        while integer > 0
          result.prepend(BASE62_CHARS[integer % 62])
          integer /= 62
        end
        result
      end
    end
  end
end

