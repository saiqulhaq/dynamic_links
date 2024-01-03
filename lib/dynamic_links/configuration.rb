module DynamicLinks
  class Configuration
    attr_accessor :shortening_strategy, :redis_config,
                  :redis_pool_size, :redis_pool_timeout

    def initialize
      @shortening_strategy = :MD5  # Default strategy
      @redis_config = {}  # Default to an empty hash, can be overridden in configuration
      @redis_pool_size = 5  # Default pool size
      @redis_pool_timeout = 5  # Default timeout in seconds
    end
  end
end

