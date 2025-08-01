# frozen_string_literal: true

require 'test_helper'
require 'mocha/minitest'

module DynamicLinks
  # @author Saiqul Haq <saiqulhaq@gmail.com>
  class StrategyFactoryTest < ActiveSupport::TestCase
    test 'get_strategy should return MD5Strategy for :md5' do
      strategy = StrategyFactory.get_strategy(:md5)
      assert_instance_of ShorteningStrategies::MD5Strategy, strategy
    end

    test 'get_strategy should return SHA256Strategy for :sha256' do
      strategy = StrategyFactory.get_strategy(:sha256)
      assert_instance_of ShorteningStrategies::SHA256Strategy, strategy
    end

    test 'get_strategy should return CRC32Strategy for :crc32' do
      strategy = StrategyFactory.get_strategy(:crc32)
      assert_instance_of ShorteningStrategies::CRC32Strategy, strategy
    end

    test 'get_strategy should return NanoIDStrategy for :nano_id' do
      StrategyFactory.stubs(:ensure_nanoid_available).returns(true)
      strategy = StrategyFactory.get_strategy(:nano_id)
      assert_instance_of ShorteningStrategies::NanoIDStrategy, strategy
    end

    test 'get_strategy should return RedisCounterStrategy for :redis_counter' do
      StrategyFactory.stubs(:ensure_redis_available).returns(true)
      strategy = StrategyFactory.get_strategy(:redis_counter)
      assert_instance_of ShorteningStrategies::RedisCounterStrategy, strategy
    end

    test 'get_strategy should return MockStrategy for :mock' do
      strategy = StrategyFactory.get_strategy(:mock)
      assert_instance_of ShorteningStrategies::MockStrategy, strategy
    end

    test 'get_strategy should raise for unknown strategy' do
      assert_raises(RuntimeError) { StrategyFactory.get_strategy(:unknown) }
    end

    test 'ensure_nanoid_available should raise if nanoid is not available' do
      StrategyFactory.stubs(:require).with('nanoid').raises(LoadError)
      assert_raises(RuntimeError) { StrategyFactory.ensure_nanoid_available }
    end

    test 'ensure_redis_available should raise if redis is not available' do
      StrategyFactory.stubs(:require).with('redis').raises(LoadError)
      assert_raises(RuntimeError) { StrategyFactory.ensure_redis_available }
    end

    test 'ensure_redis_available should raise if connection_pool is not available' do
      StrategyFactory.stubs(:require).with('redis').returns(true)
      StrategyFactory.stubs(:require).with('connection_pool').raises(LoadError)
      assert_raises(RuntimeError) { StrategyFactory.ensure_redis_available }
    end
  end
end
