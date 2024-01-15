require "test_helper"
require "minitest/mock"

class DynamicLinksTest < ActiveSupport::TestCase
  def setup
    @original_strategy = DynamicLinks.configuration.shortening_strategy
    @original_async = DynamicLinks.configuration.async_processing
    @original_cache_store_config = DynamicLinks.configuration.cache_store_config
    @client = dynamic_links_clients(:one)
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
end
