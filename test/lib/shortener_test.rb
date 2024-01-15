require "test_helper"
require "minitest/mock"

# @author Saiqul Haq <saiqulhaq@gmail.com>
class DynamicLinks::ShortenerTest < ActiveSupport::TestCase
  setup do
    @shortener = DynamicLinks::Shortener.new
    @client = dynamic_links_clients(:one) # Assuming a fixture
    @url = 'https://example.com'

    # Mocks for dependencies
    @strategy_mock = Minitest::Mock.new
    @storage_mock = Minitest::Mock.new
    @locker_mock = Minitest::Mock.new
    @async_worker_mock = Minitest::Mock.new

    # Mock return values
    @shortened_path = 'shortened_url'
    @full_short_url = "#{@client.scheme}://#{@client.hostname}/#{@shortened_path}"
  end

  test "shorten method generates and returns a shortened URL" do
    @strategy_mock.expect :shorten, @shortened_path, [@url]
    @strategy_mock.expect :always_growing?, true
    @storage_mock.expect :create!, true do |args|
      args[:client] == @client && args[:url] == @url && args[:short_url] == @shortened_path
    end

    DynamicLinks::StrategyFactory.stub :get_strategy, @strategy_mock do
      @shortener.stub :storage, @storage_mock do
        assert_equal @full_short_url, @shortener.shorten(@client, @url)
      end
    end

    @strategy_mock.verify
    @storage_mock.verify
  end

  test "shorten_async method enqueues a job and returns a shortened URL" do
    lock_key = "lock_key"
    @locker_mock.expect :generate_key, lock_key, [@client, @url]
    @locker_mock.expect :locked?, false, [lock_key]
    @locker_mock.expect :lock, true, [lock_key, {url: @url, short_url: @shortened_path}]
    @strategy_mock.expect :shorten, @shortened_path, [@url]
    @async_worker_mock.expect :perform_later, true, [@client, @url, @shortened_path, lock_key]
    DynamicLinks::StrategyFactory.stub :get_strategy, @strategy_mock do
      @shortener.stub :locker, @locker_mock do
        @shortener.stub :async_worker, @async_worker_mock do
          assert_equal @full_short_url, @shortener.shorten_async(@client, @url)
        end
      end
    end

    @locker_mock.verify
    @strategy_mock.verify
    @async_worker_mock.verify
  end

  test "shorten_async method returns cached short URL if lock exists" do
    lock_key = "lock_key"
    @locker_mock.expect :generate_key, lock_key, [@client, @url]
    @locker_mock.expect :locked?, true, [lock_key]
    @locker_mock.expect :read, @shortened_path, [lock_key]
    @shortener.stub :locker, @locker_mock do
      assert_equal @full_short_url, @shortener.shorten_async(@client, @url)
    end

    @locker_mock.verify
  end
end
