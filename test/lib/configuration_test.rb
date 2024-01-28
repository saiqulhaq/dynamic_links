require 'test_helper'

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

    test 'should raise error for invalid db_infra_strategy' do
      assert_raises ArgumentError do
        @config.db_infra_strategy = :invalid_strategy
      end
    end

    test 'should raise error for invalid async_processing' do
      assert_raises ArgumentError do
        @config.async_processing = 'not a boolean'
      end
    end

    test 'should raise error for invalid redis_counter_config' do
      assert_raises ArgumentError do
        @config.redis_counter_config = 'not a RedisConfig'
      end
    end

    test 'should raise error for invalid cache_store' do
      assert_raises ArgumentError do
        @config.cache_store = 'not a Cache::Store'
      end
    end
  end
end

