# frozen_string_literal: true

module DynamicLinks
  module ShorteningStrategies
    class SHA256Strategy < BaseStrategy
      # @param url [String] The URL to shorten
      # @param min_length [Integer] The minimum length of the short URL
      # we use this parameter to increase the length of the short URL
      # in order to avoid collisions
      def shorten(url, min_length: MIN_LENGTH)
        # Create a hash of the URL
        hashed_url = Digest::SHA256.hexdigest(url)

        # Convert the first few characters of the hash into a Base62 string
        short_url = base62_encode(hashed_url[0...10].to_i(16))

        # Ensure the short URL is at least #{min_length} characters
        short_url.ljust(min_length, '0')
      end
    end
  end
end
