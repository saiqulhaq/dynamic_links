module DynamicLinks
  module ShorteningStrategies
    # Shortens the given URL using Nano ID
    # This strategy will generate a different short URL for the same given URL
    class NanoIDStrategy < BaseStrategy
      begin
        require 'nanoid'
      rescue LoadError
        raise 'Missing dependency: Please add "nanoid" to your Gemfile to use NanoIdStrategy.'
      end

      # Shortens the given URL using Nano ID
      # @param url [String] The URL to shorten (not directly used in Nano ID strategy)
      # @param size [Integer] The size (length) of the generated Nano ID
      def shorten(url, size: MIN_LENGTH)
        ::Nanoid.generate(size: size)
      end
    end
  end
end

