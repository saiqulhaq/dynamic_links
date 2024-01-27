module DynamicLinks
  module Async
    # @author Saiqul Haq <saiqulhaq@gmail.com>
    class Locker
      LockAcquisitionError = Class.new(StandardError)
      LockReleaseError = Class.new(StandardError)

      def generate_key(client, url)
        "lock:shorten_url#{client.id}:#{url_to_lock_key(url)}"
      end

      def lock_if_absent(lock_key, expires_in: 60, &block)
        locked = false
        begin
          locked = cache_store.set(lock_key, 1, ex: expires_in, nx: true)
          unless locked
            raise LockAcquisitionError, "Unable to acquire lock for key: #{lock_key}"
          end

          yield if block_given?
        rescue => e
          DynamicLinks::Logger.log_info("Locking error: #{e.message}")
          raise e
        ensure
          if locked && !unlock(lock_key)
            raise LockReleaseError, "Unable to release lock for key: #{lock_key}"
          end
        end

        locked
      end

      def unlock(lock_key)
        cache_store.del(lock_key) > 0
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
