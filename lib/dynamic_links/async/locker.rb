module DynamicLinks
  module Async
    # @author Saiqul Haq <saiqulhaq@gmail.com>
    # This is to lock/unlock a short url into cache store
    # to prevent duplicate short url creation
    class Locker
      def generate_key(client, url)
        "lock:shorten_url#{client.id}:#{url_to_lock_key(url)}"
      end

      def lock(lock_key, content)
        cache_store.set(lock_key, content, ex: 60, nx: true)
        lock_key
      end

      def locked?(lock_key)
        cache_store.read(lock_key).present?
      end

      def read(lock_key)
        cache_store.read(lock_key)
      end

      # @api private
      def cache_store(store = DynamicLinks.configuration.cache_store)
        @cache_store ||= store
      end

      private

      def url_to_lock_key(url)
        Digest::SHA256.hexdigest(url)
      end
    end
  end
end
