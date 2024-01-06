require "test_helper"
require "minitest/mock"

class DynamicLinksTest < ActiveSupport::TestCase
  def setup
    @original_strategy = DynamicLinks.configuration.shortening_strategy
    @original_async = DynamicLinks.configuration.async_processing
    @original_cache_store_config = DynamicLinks.configuration.cache_store_config
    @client = dynamic_links_clients(:one)
  end

  # clear cache store every run
  def before_all
    DynamicLinks.configuration.cache_store.clear
  end

  # Reset the configuration after each test
  def teardown
    DynamicLinks.configuration.shortening_strategy = @original_strategy
    DynamicLinks.configuration.async_processing = @original_async
    DynamicLinks.configuration.cache_store_config = @original_cache_store_config
  end

  test "it has a version number" do
    assert DynamicLinks::VERSION
  end

  test "shorten_url invokes the correct strategy and shortens URL synchronously" do
    simulate_shorten_url(:mock, false)
  end

  test "shorten_url invokes the correct strategy and shortens URL asynchronously with condition lock key is empty" do
    simulate_shorten_url(:mock, true, {
      type: :redis, redis_config: { host: 'redis', port: 6379 }
    }, false)
  end

  test "shorten_url invokes the correct strategy and shortens URL asynchronously with condition lock key is not empty" do
    simulate_shorten_url(:mock, true, {
      type: :redis, redis_config: { host: 'redis', port: 6379 }
    }, true)
  end

  test "generate_short_url returns the correct structure" do
    DynamicLinks.configure do |config|
      config.shortening_strategy = :mock
    end

    expected_short_path = 'shortened_url'
    full_short_url = "#{@client.scheme}://#{@client.hostname}/#{expected_short_path}"
    expected_response = {
      shortLink: full_short_url,
      previewLink: "#{full_short_url}?preview=true",
      warning: []
    }

    DynamicLinks.stub :shorten_url, full_short_url do
      assert_equal expected_response, DynamicLinks.generate_short_url('https://example.com', @client)
    end
  end

  private

  def simulate_shorten_url(strategy,
                           async,
                           cache_store_config = DynamicLinks::Configuration::DEFAULT_CACHE_STORE_CONFIG,
                           lock_key_exists = false)
    DynamicLinks.configure do |config|
      config.shortening_strategy = strategy
      config.async_processing = async
      config.cache_store_config = cache_store_config
    end

    strategy_mock = Minitest::Mock.new
    expected_short_path = 'shortened_url'
    full_short_url = "#{@client.scheme}://#{@client.hostname}/#{expected_short_path}"
    strategy_mock.expect :shorten, expected_short_path, ['https://example.com']
    strategy_mock.expect :always_growing?, false if !async

    cache_store_mock = Minitest::Mock.new
    cache_key = "shorten_url:#{@client.id}:#{expected_short_path}"
    lock_key = "lock:shorten_url:#{expected_short_path}"
    cache_store_mock.expect :read, lock_key_exists, [lock_key]
    if lock_key_exists
      DynamicLinks::ShorteningStrategies::MockStrategy.stub :new, strategy_mock do
        DynamicLinks.configuration.stub :cache_store, cache_store_mock do
          assert_equal full_short_url, DynamicLinks.shorten_url('https://example.com', @client)
        end
      end
    else
      cache_store_mock.expect :write, nil, [lock_key, 'locked', { expires_in: 10.minutes }]
      cache_store_mock.expect :write, nil, [cache_key, { url: 'https://example.com', short_url: expected_short_path }]

      DynamicLinks::ShorteningStrategies::MockStrategy.stub :new, strategy_mock do
        DynamicLinks.configuration.stub :cache_store, cache_store_mock do
          assert_equal full_short_url, DynamicLinks.shorten_url('https://example.com', @client)
        end
      end
    end

    strategy_mock.verify
    cache_store_mock.verify if async
  end
end
