require "test_helper"

class DynamicLinks::ShorteningStrategies::CRC32StrategyTest < ActiveSupport::TestCase
  def setup
    @url_shortener = DynamicLinks::ShorteningStrategies::CRC32Strategy.new
  end

  test "always_growing? returns false" do
    assert_equal @url_shortener.always_growing?, false
  end

  test "shorten returns a string" do
    url = "https://example.com"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
  end

  test "shorten returns a consistent short URL for the same long URL" do
    url = "https://example.com"
    first_result = @url_shortener.shorten(url)
    second_result = @url_shortener.shorten(url)
    assert_equal first_result, second_result
  end

  test "shorten returns a string of at least 5 characters" do
    url = "https://example.com"
    result = @url_shortener.shorten(url)
    assert result.length >= 5
  end

  test "shorten returns a string of at least 7 characters" do
    url = "https://example.com"
    result = @url_shortener.shorten(url, min_length: 7)
    assert result.length >= 7
  end

  test "shorten handles an empty URL" do
    url = ""
    short_url = @url_shortener.shorten(url)
    assert_not_nil short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::CRC32Strategy::MIN_LENGTH
  end

  test "shorten handles a very long URL" do
    url = "https://example.com/" + "a" * 500
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::CRC32Strategy::MIN_LENGTH
  end

  test "shorten handles non-URL strings" do
    url = "this is not a valid URL"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::CRC32Strategy::MIN_LENGTH
  end

  test "shorten handles URL with query parameters" do
    url = "https://example.com?param1=value1&param2=value2"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::CRC32Strategy::MIN_LENGTH
  end

  test "shorten handles URL with special characters" do
    url = "https://example.com/path?query=特殊文字#fragment"
    short_url = @url_shortener.shorten(url)
    assert_kind_of String, short_url
    assert short_url.length >= DynamicLinks::ShorteningStrategies::CRC32Strategy::MIN_LENGTH
  end
end
