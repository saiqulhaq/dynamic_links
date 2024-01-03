module DynamicLinks
  class Configuration
    attr_accessor :shortening_strategy, :redis_config

    def initialize
      @shortening_strategy = :MD5  # Default strategy
      @redis_config = {}  # Default to an empty hash, can be overridden in configuration
    end
  end
end

