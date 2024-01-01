require "test_helper"
require "minitest/mock"

class DynamicLinksTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert DynamicLinks::VERSION
  end

  test "shorten_url invokes the correct strategy and shortens URL" do
    DynamicLinks.configure do |config|
      config.shortening_strategy = :Mock
    end

    strategy_mock = Minitest::Mock.new
    strategy_mock.expect :shorten, 'shortened_url', ['https://example.com']

    DynamicLinks::ShorteningStrategies::MockStrategy.stub :new, strategy_mock do
      assert_equal 'shortened_url', DynamicLinks.shorten_url('https://example.com')
    end

    strategy_mock.verify
  end

  test "generate_short_url returns the correct structure" do
    DynamicLinks.configure do |config|
      config.shortening_strategy = :Mock
    end

    expected_response = {
      shortLink: 'shortened_url',
      previewLink: 'shortened_url?preview=true',
      warning: []
    }

    DynamicLinks.stub :shorten_url, 'shortened_url' do
      assert_equal expected_response, DynamicLinks.generate_short_url('https://example.com')
    end
  end
end
