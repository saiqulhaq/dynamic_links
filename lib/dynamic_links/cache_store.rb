# Usage
# cache_store = DynamicLinks::CacheStore.new(DynamicLinks.configuration.cache_store_config)
# cache_store.write("some_key", "some_value")
# value = cache_store.read("some_key")
# cache_store.delete("some_key")
module DynamicLinks
  class CacheStore
    def initialize(config)
      @store = case config[:type]
               when :redis
                 Redis.new(config[:redis_config])
               when :memcached
                 Memcached.new(config[:memcached_config])
               else
                 raise "Unsupported cache store type"
               end
    end

    # if config type is Redis, then the options are:
    # :ex => Integer: Set the specified expire time, in seconds.
    # :px => Integer: Set the specified expire time, in milliseconds.
    # :exat => Integer : Set the specified Unix time at which the key will expire, in seconds.
    # :pxat => Integer : Set the specified Unix time at which the key will expire, in milliseconds.
    # :nx => true: Only set the key if it does not already exist.
    # :xx => true: Only set the key if it already exist.
    # :keepttl => true: Retain the time to live associated with the key.
    # :get => true: Return the old string stored at key, or nil if key did not exist.
    def write(key, value, options = {})
      case @store
      when Redis
        if options == {}
          @store.set(key, value)
        else
          @store.set(key, value, options)
        end
      when Memcached
        @store.cas(key, value, options)
      end
    end

    def read(key)
      @store.get(key)
    end

    def delete(key)
      @store.del(key)
    end
  end
end

