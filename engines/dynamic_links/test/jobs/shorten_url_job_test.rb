# frozen_string_literal: true

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
      
      # Set up the lock using the locker's increment method to simulate proper lock acquisition
      @locker.cache_store.write(@lock_key, 1, expires_in: 60)
    end

    test 'perform should create a shortened URL if strategy#always_growing? is true' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)

      @storage.expects(:create!).with(client: @client, url: @url, short_url: "#{@short_url}11", expires_at: nil)
      @job.perform(@client, @url, "#{@short_url}11", @lock_key)
    end

    test 'perform should find_or_create a shortened URL if strategy#always_growing? is false' do
      @strategy.stubs(:always_growing?).returns(false)
      @job.stubs(:storage).returns(@storage)

      @storage.expects(:find_or_create!).with(@client, "#{@short_url}12", @url, expires_at: nil)
      @job.perform(@client, @url, "#{@short_url}12", @lock_key)
    end

    test 'perform should unlock the lock_key after successful execution' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)

      @storage.expects(:create!).with(client: @client, url: @url, short_url: "#{@short_url}13", expires_at: nil)
      @job.perform(@client, @url, "#{@short_url}13", @lock_key)
      refute @locker.locked?(@lock_key)
    end

    test 'perform should log error and re-raise exception on failure' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)
      @storage.stubs(:create!).raises(ShorteningFailed.new('Creation failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error in ShortenUrlJob/))

      assert_raises ShorteningFailed do
        @job.perform(@client, @url, "#{@short_url}123", @lock_key)
      end

      assert @locker.locked?(@lock_key)
    end

    test 'perform retries on short URL collision and mints a new code on success' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)
      # First strategy.shorten returns the initial code; after the
      # collision the job asks the strategy for a fresh code, and the
      # second create! succeeds.
      @strategy.stubs(:shorten).returns('newcode99')
      @storage.stubs(:create!)
        .with(client: @client, url: @url, short_url: "#{@short_url}14", expires_at: nil)
        .raises(duplicate_short_url_error)
      @storage.expects(:create!)
        .with(client: @client, url: @url, short_url: 'newcode99', expires_at: nil)
        .returns(true)

      @job.perform(@client, @url, "#{@short_url}14", @lock_key)
      refute @locker.locked?(@lock_key)
    end

    test 'perform re-raises after max collision attempts' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)
      @strategy.stubs(:shorten).returns('retry1', 'retry2', 'retry3')
      @storage.stubs(:create!).raises(duplicate_short_url_error)
      DynamicLinks::Logger.stubs(:log_error)

      assert_raises(ActiveRecord::RecordInvalid) do
        @job.perform(@client, @url, "#{@short_url}15", @lock_key)
      end
    end

    test 'perform does NOT retry on non-collision RecordInvalid' do
      @strategy.stubs(:always_growing?).returns(true)
      @job.stubs(:storage).returns(@storage)
      @strategy.stubs(:shorten).returns("#{@short_url}16")
      record = DynamicLinks::ShortenedUrl.new
      record.errors.add(:expires_at, 'must be in the future')
      invalid = ActiveRecord::RecordInvalid.new(record)
      @storage.stubs(:create!).raises(invalid)
      DynamicLinks::Logger.stubs(:log_error)

      assert_raises(ActiveRecord::RecordInvalid) do
        @job.perform(@client, @url, "#{@short_url}16", @lock_key)
      end
    end

    private

    # RecordInvalid with the :short_url uniqueness message — the same
    # shape Rails raises for the model's `validates :short_url,
    # uniqueness: { scope: :client_id }` constraint.
    def duplicate_short_url_error
      record = DynamicLinks::ShortenedUrl.new
      record.errors.add(:short_url, 'has already been taken')
      ActiveRecord::RecordInvalid.new(record)
    end
  end
end
