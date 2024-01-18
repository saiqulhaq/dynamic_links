module DynamicLinks
  module Async
    # @author Saiqul Haq <saiqulhaq@gmail.com>
    # This is to lock/unlock a short url into cache store
    # to prevent duplicate short url creation
    class Locker
      def generate_key(client, url)
        "lock:shorten_url#{client.id}:#{url_to_lock_key(url)}"
      end

      def lock_if_absent(lock_key, expires_in: 60, &block)
        locked = cache_store.set(lock_key, 1, ex: expires_in, nx: true)

        if locked
          begin
            yield
          ensure
            unlock(lock_key)
          end
        end

        locked
      end

      def unlock(lock_key)
        cache_store.del(lock_key)
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
