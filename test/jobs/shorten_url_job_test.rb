require 'test_helper'
require 'mocha/minitest'

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class ShortenUrlJobTest < ActiveJob::TestCase
    setup do
      @client = dynamic_links_clients(:one) # Replace with your fixture or factory for clients
      @url = 'https://example.com'
      @short_url = 'abc123'
      @lock_key = 'lock_key'
      @strategy = mock('strategy')
      @storage = mock('storage')
      @locker = DynamicLinks::Async::Locker.new
      @job = ShortenUrlJob.new
      StrategyFactory.stubs(:get_strategy).returns(@strategy)
      @locker.cache_store.write(@lock_key, true)
    end

    test 'perform should create a shortened URL if startegy#always_growing? is true' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)

      @storage.expects(:create!).with(client: @client, url: @url, short_url: "#{@short_url}11")
      @job.perform(@client, @url, "#{@short_url}11", @lock_key)
    end

    test 'perform should find_or_create a shortened URL if strategy#always_growing? is false' do
      @strategy.stubs(:always_growing?).returns(false)
      @job.stubs(:storage).returns(@storage)

      @storage.expects(:find_or_create!).with(@client, "#{@short_url}12", @url)
      @job.perform(@client, @url, "#{@short_url}12", @lock_key)
    end

    test 'perform should unlock the lock_key after successful execution' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)

      @storage.expects(:create!).with(client: @client, url: @url, short_url: "#{@short_url}13")
      @job.perform(@client, @url, "#{@short_url}13", @lock_key)
      refute @locker.locked?(@lock_key)
    end

    test 'perform should log error and re-raise exception on failure' do
      @strategy.stubs(:always_growing?).returns(true)
      ShortenedUrl.stubs(:create!).raises(ShorteningFailed.new('Creation failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error in ShortenUrlJob/))

      assert_raises ShorteningFailed do
        @job.perform(@client, @url, "#{@short_url}123", @lock_key)
      end

      assert @locker.locked?(@lock_key)
    end
  end
end
