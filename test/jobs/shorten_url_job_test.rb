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
      @locker = DynamicLinks::Async::Locker.new
      @job = ShortenUrlJob.new
      StrategyFactory.stubs(:get_strategy).returns(@strategy)
      @locker.lock(@lock_key)
    end

    test 'perform should create a shortened URL if startegy#always_growing? is true' do
      @strategy.stubs(:always_growing?).returns(true)
      ShortenedUrl.stubs(:create!)

      @job.perform(@client, @url, "#{@short_url}11", @lock_key)

      assert @locker.locked?(@lock_key).nil?
    end

    test 'perform should find_or_create a shortened URL if startegy#always_growing? is false' do
      @strategy.stubs(:always_growing?).returns(false)
      ShortenedUrl.stubs(:find_or_create!)

      @job.perform(@client, @url, "#{@short_url}12", @lock_key)

      assert @locker.locked?(@lock_key).nil?
    end


    test 'perform should log error and re-raise exception on failure' do
      @strategy.stubs(:always_growing?).returns(true)
      ShortenedUrl.stubs(:create!).raises(StandardError.new('Creation failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error in ShortenUrlJob/))

      assert_raises StandardError do
        @job.perform(@client, @url, "#{@short_url}123", @lock_key)
      end

      refute @locker.locked?(@lock_key).nil?
    end
  end
end
