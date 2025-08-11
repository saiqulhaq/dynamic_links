# frozen_string_literal: true

module DynamicLinks
  module ShorteningStrategies
    # Shortens the given URL using Nano ID
    # This strategy will generate a different short URL for the same given URL
    class NanoIDStrategy < BaseStrategy
      # Shortens the given URL using Nano ID
      # @param url [String] The URL to shorten (not directly used in Nano ID strategy)
      # @param min_length [Integer] The size (length) of the generated Nano ID
      def shorten(_url, min_length: MIN_LENGTH)
        # Generate the Nano ID with the requested minimum length
        short_url = ::Nanoid.generate(size: min_length)

        # Ensure it doesn't exceed the maximum length
        enforce_max_length(short_url)
      end

      def always_growing?
        true # This strategy always generates a new shortened URL
      end
    end
  end
end
