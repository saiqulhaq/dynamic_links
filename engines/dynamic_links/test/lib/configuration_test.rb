# frozen_string_literal: true

require 'test_helper'
require 'dalli'

module DynamicLinks
  class ConfigurationTest < ActiveSupport::TestCase
    setup do
      @config = Configuration.new
    end

    test 'should raise error for invalid shortening_strategy' do
      assert_raises ArgumentError do
        @config.shortening_strategy = :invalid_strategy
      end
    end

    test 'should raise error for invalid enable_rest_api' do
      assert_raises ArgumentError do
        @config.enable_rest_api = 'not a boolean'
      end
    end

    test 'should raise error for invalid async_processing' do
      assert_raises ArgumentError do
        @config.async_processing = 'not a boolean'
      end
    end

    test 'false is valid async_processing' do
      @config.async_processing = false
      assert_equal @config.async_processing, false
    end

    test 'true is valid async_processing' do
      @config.async_processing = true
      assert_equal @config.async_processing, true
    end

    test 'should raise error for invalid redis_counter_config' do
      assert_raises ArgumentError do
        @config.redis_counter_config = 'not a RedisConfig'
      end
    end

    test 'valid redis_counter_config should not raise error' do
      valid_redis_config = RedisConfig.new
      @config.redis_counter_config = valid_redis_config
      assert_equal @config.redis_counter_config, valid_redis_config
    end

    test 'should raise error for invalid cache_store' do
      assert_raises ArgumentError do
        @config.cache_store = 'not a Cache::Store'
      end
    end

    test 'valid redis cache_store should not raise error' do
      valid_cache_store = ActiveSupport::Cache::RedisCacheStore.new(url: 'redis://localhost:6379/0')
      @config.cache_store = valid_cache_store
      assert_equal @config.cache_store, valid_cache_store
    end

    test 'valid Memcached cache_store should not raise error' do
      valid_cache_store = ActiveSupport::Cache::MemCacheStore.new('localhost:11211')
      @config.cache_store = valid_cache_store
      assert_equal @config.cache_store, valid_cache_store
    end

    test 'should raise error for nil redis_counter_config' do
      assert_raises ArgumentError do
        @config.redis_counter_config = nil
      end
    end

    test 'should raise error for number redis_counter_config' do
      assert_raises ArgumentError do
        @config.redis_counter_config = 123
      end
    end

    test 'should set valid max_shortened_url_length' do
      @config.max_shortened_url_length = 15
      assert_equal 15, @config.max_shortened_url_length
    end

    test 'should raise error for invalid max_shortened_url_length' do
      assert_raises ArgumentError do
        @config.max_shortened_url_length = 'not a number'
      end

      assert_raises ArgumentError do
        @config.max_shortened_url_length = -1
      end

      assert_raises ArgumentError do
        @config.max_shortened_url_length = 0
      end

      assert_raises ArgumentError do
        @config.max_shortened_url_length = nil
      end

      assert_raises ArgumentError do
        @config.max_shortened_url_length = 3000  # exceeds 2048 limit
      end
    end

    test 'should have default max_shortened_url_length' do
      assert_equal Configuration::DEFAULT_MAX_SHORTENED_URL_LENGTH, @config.max_shortened_url_length
    end
  end
end
