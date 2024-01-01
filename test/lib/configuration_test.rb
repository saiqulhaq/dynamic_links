require 'test_helper'

module DynamicLinks
  class ConfigurationTest < ActiveSupport::TestCase
    def setup
      @config = DynamicLinks::Configuration.new
    end

    test "should initialize with default shortening_strategy" do
      assert_equal :MD5, @config.shortening_strategy, 'Default shortening_strategy is not set to :MD5'
    end

    test "should allow setting a different shortening_strategy" do
      @config.shortening_strategy = :CRC32
      assert_equal :CRC32, @config.shortening_strategy, 'Unable to set a different shortening_strategy'
    end
  end
end

