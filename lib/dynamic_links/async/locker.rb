# @author Saiqul Haq <saiqulhaq@gmail.com>
module DynamicLinks
  module Async
    # This is to lock/unlock a short url into cache store
    # to prevent duplicate short url creation
    class Locker
      def generate_key(client, url)
        "lock:shorten_url#{client.id}:#{url_to_key(url)}"
      end

      # allow dependency injection
      def cache_store(store = DynamicLinks.configuration.cache_store)
        @cache_store ||= store
      end

      def lock(client, key, content)
        lock_key = generate_key(client, key)
        cache_store.set(lock_key, content, ex: 60, nx: true)
        lock_key
      end

      def locked?(key)
        cache_store.read(key).present?
      end

      def read(key)
        cache_store.read(key)
      end

      private

      def url_to_key(url)
        Digest::SHA256.hexdigest(url)
      end
    end
  end
end
