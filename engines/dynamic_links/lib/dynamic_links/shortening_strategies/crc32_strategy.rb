# frozen_string_literal: true

module DynamicLinks
  module ShorteningStrategies
    class CRC32Strategy < BaseStrategy
      # @param url [String] The URL to shorten
      # @param min_length [Integer] The minimum length of the short URL
      def shorten(url, min_length: MIN_LENGTH)
        # Create a CRC32 hash of the URL
        hashed_url = Zlib.crc32(url).to_s(16)

        # Convert the CRC32 hash into a Base62 string
        short_url = base62_encode(hashed_url.to_i(16))

        # Ensure the short URL is at least #{min_length} characters long
        short_url = short_url.ljust(min_length, '0')

        # Ensure it doesn't exceed the maximum length
        enforce_max_length(short_url)
      end
    end
  end
end
