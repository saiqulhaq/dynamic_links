require "test_helper"

class DynamicLinks::ShorteningStrategies::BaseStrategyTest < ActiveSupport::TestCase
  def setup
    @url_shortener = DynamicLinks::ShorteningStrategies::BaseStrategy.new
  end

  test "raise shorten method not implemented" do
  	url = "https://example.com"
    assert_raises(NotImplementedError, "You must implement the shorten method") {@url_shortener.shorten(url)}
  end

  test "always_growing returns false" do
    assert_equal @url_shortener.always_growing?, false
  end
end
