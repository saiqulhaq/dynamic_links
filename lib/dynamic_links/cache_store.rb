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

    def write(key, value, options = {})
      case @store
      when Redis
        # Use Redis transaction commands
        @store.multi do |multi|
          multi.set(key, value, options)
        end
      when Memcached
        # Use Memcached CAS command
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

