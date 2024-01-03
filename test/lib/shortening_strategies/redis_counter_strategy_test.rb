require "test_helper"
require_relative './../../../lib/dynamic_links/strategy_factory'

class DynamicLinks::ShorteningStrategies::RedisCounterStrategyTest < ActiveSupport::TestCase
  def setup
    @url_shortener = DynamicLinks::StrategyFactory.get_strategy(:redis_counter)
  end

  test "shorten returns a string" do
    url = "https://example.com"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
  end

  test "shorten returns a different short URL for the same long URL" do
    url = "https://example.com"
    first_result = @url_shortener.shorten(url)
    second_result = @url_shortener.shorten(url)
    assert_not_equal first_result, second_result
  end

  test "shorten returns a string to be 12 characters" do
    url = "https://example.com"
    result = @url_shortener.shorten(url)
    assert result.length >= DynamicLinks::ShorteningStrategies::RedisCounterStrategy::MIN_LENGTH
  end

  test "shorten handles an empty URL" do
    url = ""
    short_url = @url_shortener.shorten(url)
    assert_not_nil short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::RedisCounterStrategy::MIN_LENGTH
  end

  test "shorten handles a very long URL" do
    url = "https://example.com/" + "a" * 500
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::RedisCounterStrategy::MIN_LENGTH
  end

  test "shorten handles non-URL strings" do
    url = "this is not a valid URL"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::RedisCounterStrategy::MIN_LENGTH
  end

  test "shorten handles URL with query parameters" do
    url = "https://example.com?param1=value1&param2=value2"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::RedisCounterStrategy::MIN_LENGTH
  end

  test "shorten handles URL with special characters" do
    url = "https://example.com/path?query=特殊文字#fragment"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::RedisCounterStrategy::MIN_LENGTH
  end
end
