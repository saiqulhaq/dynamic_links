module DynamicLinks
  class MemcachedCacheStore < BaseCacheStore
    def initialize(config)
      @memcached = Dalli::Client.new(config)
    end

    def write(key, value, options = {})
      @memcached.cas(key, value, options)
    end

    def read(key)
      @memcached.get(key)
    end

    def delete(key)
      @memcached.delete(key)
    end
  end
end

