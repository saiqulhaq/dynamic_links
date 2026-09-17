# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

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
      @lock_key = @locker.generate_lock_key(@client, @url)
      @cache_store = DynamicLinks.configuration.cache_store
    end

    test 'with always_growing is true, shorten should create a shortened URL and save it' do
      @strategy.stubs(:shorten).returns(@short_url)
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!).returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url)

      assert_match @short_url, result
      assert_equal "#{@client.scheme}://#{@client.hostname}/#{@short_url}", result
    end

    test 'with always_growing is false, shorten should create a shortened URL and save it' do
      @strategy.stubs(:shorten).returns(@short_url)
      @strategy.stubs(:always_growing?).returns(false)
      @storage.stubs(:create!).returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url)

      assert_match @short_url, result
      assert_equal "#{@client.scheme}://#{@client.hostname}/#{@short_url}", result
    end

    test 'shorten retries on short_url collision and succeeds on a later attempt' do
      @strategy.stubs(:shorten).returns('collide1', 'collide2', 'unique1')
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!)
        .raises(duplicate_short_url_error)
        .then.raises(duplicate_short_url_error)
        .then.returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url)

      assert_equal "#{@client.scheme}://#{@client.hostname}/unique1", result
    end

    test 'shorten raises after max attempts when collisions persist' do
      @strategy.stubs(:shorten).returns('a', 'b', 'c')
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!).raises(duplicate_short_url_error)
      DynamicLinks::Logger.stubs(:log_error)

      assert_raises(ActiveRecord::RecordInvalid) do
        @shortener.shorten(@client, @url)
      end
    end

    test 'shorten retries find_or_create on RecordInvalid when not always_growing' do
      @strategy.stubs(:shorten).returns('collide1', 'unique1')
      @strategy.stubs(:always_growing?).returns(false)
      @storage.stubs(:find_or_create!).raises(duplicate_short_url_error).then.returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url)

      assert_equal "#{@client.scheme}://#{@client.hostname}/unique1", result
    end

    test 'shorten does NOT retry on non-collision RecordInvalid errors' do
      @strategy.stubs(:shorten).returns(@short_url)
      @strategy.stubs(:always_growing?).returns(true)
      # RecordInvalid with errors on :expires_at (not :short_url) — not a collision.
      record = ShortenedUrl.new
      record.errors.add(:expires_at, 'must be in the future')
      invalid = ActiveRecord::RecordInvalid.new(record)
      @storage.stubs(:create!).raises(invalid)
      DynamicLinks::Logger.stubs(:log_error)

      assert_raises(ActiveRecord::RecordInvalid) do
        @shortener.shorten(@client, @url)
      end
    end

    test 'shorten retries on ActiveRecord::RecordNotUnique without RecordInvalid' do
      @strategy.stubs(:shorten).returns('collide1', 'unique1')
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!).raises(ActiveRecord::RecordNotUnique.new('')).then.returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url)

      assert_equal "#{@client.scheme}://#{@client.hostname}/unique1", result
    end

    test 'shorten should handle exceptions and log errors' do
      @strategy.stubs(:shorten).raises(ShorteningFailed.new('shortening failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error shortening URL/))

      assert_raises ShorteningFailed do
        @shortener.shorten(@client, @url)
      end
    end

    test 'shorten_async should enqueue a job to shorten the URL' do
      lock_key = 'lock_key'
      @locker.stubs(:generate_lock_key).returns(lock_key)
      @locker.stubs(:lock_if_absent).yields
      @strategy.stubs(:shorten).returns(@short_url)
      @async_worker.expects(:perform_later).with(@client, @url, @short_url, lock_key, nil)

      @shortener.shorten_async(@client, @url)
    end

    test 'shorten_async should handle exceptions and log errors' do
      @locker.stubs(:generate_lock_key).returns('lock_key')
      @locker.stubs(:lock_if_absent).raises(ShorteningFailed.new('async shortening failed'))
      DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/Error shortening URL asynchronously/))

      assert_raises ShorteningFailed do
        @shortener.shorten_async(@client, @url)
      end
    end

    test 'shorten should create a shortened URL with expires_at' do
      expires_at = Time.zone.now + 1.day
      @strategy.stubs(:shorten).returns(@short_url)
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!).returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url, expires_at: expires_at)

      assert_match @short_url, result
      assert_equal "#{@client.scheme}://#{@client.hostname}/#{@short_url}", result
    end

    test 'shorten should handle expires_at as string' do
      expires_at = (Time.zone.now + 1.day).iso8601
      @strategy.stubs(:shorten).returns(@short_url)
      @strategy.stubs(:always_growing?).returns(true)
      @storage.stubs(:create!).returns(ShortenedUrl.new)

      result = @shortener.shorten(@client, @url, expires_at: expires_at)

      assert_match @short_url, result
    end

    test 'shorten_async should enqueue a job with expires_at' do
      lock_key = 'lock_key'
      expires_at = Time.zone.now + 1.day
      @locker.stubs(:generate_lock_key).returns(lock_key)
      @locker.stubs(:lock_if_absent).yields
      @strategy.stubs(:shorten).returns(@short_url)
      @async_worker.expects(:perform_later).with(@client, @url, @short_url, lock_key, expires_at)

      @shortener.shorten_async(@client, @url, expires_at: expires_at)
    end

    private

    # Build a RecordInvalid whose error message lives on :short_url —
    # the same shape Rails raises for the `validates :short_url,
    # uniqueness: { scope: :client_id }` constraint, so the shortener
    # recognises it as a real collision.
    def duplicate_short_url_error
      record = ShortenedUrl.new
      record.errors.add(:short_url, 'has already been taken')
      ActiveRecord::RecordInvalid.new(record)
    end
  end
end
