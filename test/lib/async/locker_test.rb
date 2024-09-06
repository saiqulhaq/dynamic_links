require 'test_helper'
require 'mocha/minitest'

module DynamicLinks
  module Async
    # @author Saiqul Haq <saiqulhaq@gmail.com>
    class LockerTest < ActiveSupport::TestCase
      setup do
        @cache_store = ActiveSupport::Cache::MemoryStore.new
        @locker = Locker.new(@cache_store)
        @client = OpenStruct.new(id: 123)
        @url = 'https://example.com'
        @lock_key = @locker.generate_lock_key(@client, @url)
      end

      test 'generate_lock_key should create a unique lock key' do
        expected_key = "lock:shorten_url123:#{Digest::SHA256.hexdigest(@url)}"
        assert_equal expected_key, @locker.generate_lock_key(@client, @url)
      end

      test 'locked? should return false if lock is not present' do
        assert_not @locker.locked?(@lock_key)
      end

      test 'locked? should return true if lock is present' do
        @cache_store.write(@lock_key, true)
        assert @locker.locked?(@lock_key)
      end

      test 'lock_if_absent should acquire lock and execute block' do
        executed = false
        result = @locker.lock_if_absent(@lock_key) do
          executed = true
          'block result'
        end

        assert executed, 'Block should have been executed'
        assert result, 'lock_if_absent should return true when lock is acquired'
        assert @locker.locked?(@lock_key), 'Lock should be not released after block execution'
      end
            
      test 'lock_if_absent should raise error if not able acquire lock' do
        @cache_store.write(@lock_key, 1, expires_in: 60)

        assert_raises(Locker::LockAcquisitionError) do 
          @locker.lock_if_absent(@lock_key) { value = 100 }
        end
      end

      test 'lock_if_absent should log error and re-raise exception on locking error' do
        error_message = 'Simulated locking error'

        @cache_store.stubs(:increment).raises(StandardError, error_message)

        DynamicLinks::Logger.expects(:log_error).with("Locking error: #{error_message}")

        assert_raises(StandardError) do
          @locker.lock_if_absent(@lock_key) { value = 100 }
        end
      end

      test 'unlock should delete the lock key and return true' do
        @cache_store.write(@lock_key, true)
        assert @locker.unlock(@lock_key), 'unlock should return true when lock is deleted'
        assert_not @locker.locked?(@lock_key), 'Lock key should be deleted'
      end

      test 'unlock should raise LockReleaseError if lock key does not exist' do
        assert_raises(Locker::LockReleaseError) do
          @locker.unlock(@lock_key)
        end
      end
    end
  end
end
