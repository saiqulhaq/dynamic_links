require "test_helper"
require "minitest/mock"

# @author Saiqul Haq <saiqulhaq@gmail.com>
class DynamicLinks::Async::LockerTest < ActiveSupport::TestCase
  setup do
    @locker = DynamicLinks::Async::Locker.new
    @client = dynamic_links_clients(:one)
    @url = 'https://example.com'
    @lock_key = @locker.generate_key(@client, @url)
    @cache_store = mock()
    @locker.stubs(:cache_store).returns(@cache_store)
  end

  test 'should acquire lock if absent and execute block' do
    @cache_store.expects(:set).with(@lock_key, 1, ex: 60, nx: true).returns(true)
    @cache_store.expects(:del).with(@lock_key).returns(1)

    result = @locker.lock_if_absent(@lock_key) do
      'block result'
    end

    assert_equal true, result
  end

  test 'should raise LockAcquisitionError if unable to acquire lock' do
    @cache_store.expects(:set).with(@lock_key, 1, ex: 60, nx: true).returns(false)

    assert_raises DynamicLinks::Async::Locker::LockAcquisitionError do
      @locker.lock_if_absent(@lock_key) do
        'block result'
      end
    end
  end

  test 'should raise LockReleaseError if unable to release lock' do
    @cache_store.expects(:set).with(@lock_key, 1, ex: 60, nx: true).returns(true)
    @cache_store.expects(:del).with(@lock_key).returns(0)

    assert_raises DynamicLinks::Async::Locker::LockReleaseError do
      @locker.lock_if_absent(@lock_key) do
        'block result'
      end
    end
  end
end

