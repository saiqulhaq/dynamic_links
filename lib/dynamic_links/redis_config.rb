# @author Saiqul Haq <saiqulhaq@gmail.com>
module DynamicLinks
  class RedisConfig
    attr_accessor :config, :pool_size, :pool_timeout

    def initialize
      # Default to an empty hash, can be overridden
      @config = {
        # host: 'localhost',
        # port: 6379
      }
      @pool_size = 5          # Default pool size
      @pool_timeout = 5       # Default timeout in seconds
    end
  end
end
