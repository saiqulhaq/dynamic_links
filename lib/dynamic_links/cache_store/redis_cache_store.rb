module DynamicLinks
  class RedisCacheStore < BaseCacheStore
    def initialize(config)
      @redis = Redis.new(config)
    end

    # @param [String] key
    # @param [String] value
    # @param [Hash] options. valid options:
    # :ex => Integer: Set the specified expire time, in seconds.
    # :px => Integer: Set the specified expire time, in milliseconds.
    # :exat => Integer : Set the specified Unix time at which the key will expire, in seconds.
    # :pxat => Integer : Set the specified Unix time at which the key will expire, in milliseconds.
    # :nx => true: Only set the key if it does not already exist.
    # :xx => true: Only set the key if it already exist.
    # :keepttl => true: Retain the time to live associated with the key.
    # :get => true: Return the old string stored at key, or nil if key did not exist.
    def write(key, value, options = {})
      @redis.set(key, value, ex: options[:expires_in])
    end

    def read(key)
      @redis.get(key)
    end

    def delete(key)
      @redis.del(key)
    end

    def clear
      @redis.flushall
    end
  end
end
