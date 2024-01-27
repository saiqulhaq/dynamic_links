require "test_helper"
require "minitest/mock"

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class ShortenerTest < ActiveSupport::TestCase
    setup do
      @client = dynamic_links_clients(:one)
      @url = 'https://example.com'
      @short_url = 'abc123'
      @locker = DynamicLinks::Async::Locker.new
      @strategy = mock('strategy')
      @storage = ShortenedUrl
      @async_worker = mock('async_worker')
      @shortener = Shortener.new(locker: @locker, strategy: @strategy, storage: @storage, async_worker: @async_worker)
    end

    test 'shorten should create a shortened URL and save it' do
      @strategy.stubs(:shorten).returns(@short_url)
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!).returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url)

      assert_match @short_url, result
      assert_equal "#{@client.scheme}://#{@client.hostname}/#{@short_url}", result
    end

    test 'shorten should handle exceptions and log errors' do
      @strategy.stubs(:shorten).raises(StandardError.new('shortening failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error shortening URL/))

      assert_raises StandardError do
        @shortener.shorten(@client, @url)
      end
    end

    test 'shorten_async should enqueue a job to shorten the URL' do
      lock_key = 'lock_key'
      @locker.stubs(:generate_lock_key).returns(lock_key)
      @locker.stubs(:lock_if_absent).yields
      @strategy.stubs(:shorten).returns(@short_url)
      @async_worker.expects(:perform_later).with(@client, @url, @short_url, lock_key)

      @shortener.shorten_async(@client, @url)
    end

    test 'shorten_async should handle exceptions and log errors' do
      @locker.stubs(:generate_lock_key).returns('lock_key')
      @locker.stubs(:lock_if_absent).raises(StandardError.new('async shortening failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error shortening URL asynchronously/))

      assert_raises StandardError do
        @shortener.shorten_async(@client, @url)
      end
    end
  end
end

