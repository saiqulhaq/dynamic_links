module DynamicLinks
  module Async
    # @author Saiqul Haq <saiqulhaq@gmail.com>
    class Locker
      LockAcquisitionError = Class.new(StandardError)
      LockReleaseError = Class.new(StandardError)
      attr_reader :cache_store

      def initialize(cache_store = DynamicLinks.configuration.cache_store)
        @cache_store = cache_store
      end

      def generate_lock_key(client, url)
        "lock:shorten_url#{client.id}:#{url_to_lock_key(url)}"
      end

      def locked?(lock_key)
        cache_store.exist?(lock_key)
      end

      # Acquires a lock for the given key and executes the block if lock is acquired.
      # This method won't release the lock after block execution.
      # We release the lock in the job after the job is done.
      # @param [String] lock_key, it's better to use generate_lock_key method to generate lock_key
      # @param [Integer] expires_in, default is 60 seconds
      # @param [Block] block, the block to be executed if lock is acquired
      # @return [Boolean]
      def lock_if_absent(lock_key, expires_in: 60, race_condition_ttl: 10.seconds, &block)
        is_locked = false
        begin
          cache_store.fetch(lock_key, race_condition_ttl: race_condition_ttl) do |_key, options|
            options.expires_in = expires_in
            is_locked = true
            yield if block_given?
          end

          unless is_locked
            raise LockAcquisitionError, "Unable to acquire lock for key: #{lock_key}"
          end
        rescue => e
          DynamicLinks::Logger.log_error("Locking error: #{e.message}")
          raise e
        end

        is_locked
      end

      # Deletes an entry in the cache. Returns true if an entry is deleted and false otherwise.
      # @return [Boolean]
      def unlock(lock_key)
        deleted = cache_store.delete(lock_key)
        raise LockReleaseError, "Unable to release lock for key: #{lock_key}" unless deleted
        deleted
      end

      private

      def url_to_lock_key(url)
        Digest::SHA256.hexdigest(url)
      end
    end
  end
end
