# frozen_string_literal: true

# @author Saiqul Haq <saiqulhaq@gmail.com>

module DynamicLinks
  # RedisConfig is a class to hold Redis configuration
  class RedisConfig
    attr_accessor :config, :pool_size, :pool_timeout

    # @param [Hash] config
    # Default to an empty hash, can be overridden
    #    config = {
    #      host: 'localhost',
    #      port: 6379
    #    }
    # @param [Integer] pool_size Default to 5, can be overridden
    # @param [Integer] pool_timeout Default to 5, can be overridden
    def initialize(config = {}, pool_size = 5, pool_timeout = 5)
      @config = config
      @pool_size = pool_size
      @pool_timeout = pool_timeout
    end
  end
end
