require "test_helper"
require "minitest/mock"

# @author Saiqul Haq <saiqulhaq@gmail.com>
class DynamicLinks::Async::LockerTest < ActiveSupport::TestCase
  setup do
    @client = dynamic_links_clients(:one)
    @url = 'https://example.com'
    @locker = DynamicLinks::Async::Locker.new
    @cache_mock = Minitest::Mock.new
  end

  test "generate_key returns a consistent key for a given client and url" do
    expected_key = "lock:shorten_url#{@client.id}:#{Digest::SHA256.hexdigest(@url)}"
    assert_equal expected_key, @locker.generate_key(@client, @url)
  end

  test "lock sets a value in cache store with expiration and returns lock key" do
    lock_key = @locker.generate_key(@client, @url)
    content = { url: @url, short_url: 'shortened_url' }
    options = { ex: 60, nx: true }

    @cache_mock.expect(:set, true) do |arg1, arg2, arg3|
      arg1 == lock_key && arg2 == content && arg3 == options
    end

    @locker.stub :cache_store, @cache_mock do
      assert_equal lock_key, @locker.lock(lock_key, content)
    end

    @cache_mock.verify
  end

  test "locked? returns true if key is present in cache store" do
    lock_key = @locker.generate_key(@client, @url)
    @cache_mock.expect :read, 'value', [lock_key]

    @locker.stub :cache_store, @cache_mock do
      assert @locker.locked?(lock_key)
    end

    @cache_mock.verify
  end

  test "locked? returns false if key is not present in cache store" do
    lock_key = @locker.generate_key(@client, @url)
    @cache_mock.expect :read, nil, [lock_key]

    @locker.stub :cache_store, @cache_mock do
      refute @locker.locked?(lock_key)
    end

    @cache_mock.verify
  end

  test "read returns the value from cache store for a given key" do
    lock_key = @locker.generate_key(@client, @url)
    expected_value = { url: @url, short_url: 'shortened_url' }
    @cache_mock.expect :read, expected_value, [lock_key]
    @locker.stub :cache_store, @cache_mock do
      assert_equal expected_value, @locker.read(lock_key)
    end

    @cache_mock.verify
  end
end
