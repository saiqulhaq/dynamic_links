module DynamicLinks
  module Async
    # @author Saiqul Haq <saiqulhaq@gmail.com>
    class Locker
      LockAcquisitionError = Class.new(StandardError)
      LockReleaseError = Class.new(StandardError)

      def generate_lock_key(client, url)
        "lock:shorten_url#{client.id}:#{url_to_lock_key(url)}"
      end

      def locked?(lock_key)
        cache_store.read(lock_key)
      end

      def lock(lock_key, expires_in: 60)
        cache_store.write(lock_key, 1, ex: expires_in, nx: true)
      end

      def lock_if_absent(lock_key, expires_in: 60, &block)
        locked = false
        begin
          locked = lock(lock_key, expires_in: expires_in)
          unless locked
            raise LockAcquisitionError, "Unable to acquire lock for key: #{lock_key}"
          end

          yield if block_given?
        rescue => e
          DynamicLinks::Logger.log_info("Locking error: #{e.message}")
          raise e
        end

        locked
      end

      # Deletes an entry in the cache. Returns true if an entry is deleted and false otherwise.
      # @return [Boolean]
      def unlock(lock_key)
        cache_store.delete(lock_key)
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
