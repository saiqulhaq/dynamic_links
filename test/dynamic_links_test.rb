require "test_helper"
require "minitest/mock"

class DynamicLinksTest < ActiveSupport::TestCase
  def setup
    @original_strategy = DynamicLinks.configuration.shortening_strategy
    @client = dynamic_links_clients(:one)
  end

  def teardown
    # Reset the configuration after each test
    DynamicLinks.configuration.shortening_strategy = @original_strategy
  end

  test "it has a version number" do
    assert DynamicLinks::VERSION
  end

  test "shorten_url invokes the correct strategy and shortens URL" do
    DynamicLinks.configure do |config|
      config.shortening_strategy = :mock
    end

    strategy_mock = Minitest::Mock.new
    expected_short_path = 'shortened_url'
    full_short_url = "#{@client.scheme}://#{@client.hostname}/#{expected_short_path}"
    strategy_mock.expect :shorten, expected_short_path, ['https://example.com']
    strategy_mock.expect :always_growing?, false

    DynamicLinks::ShorteningStrategies::MockStrategy.stub :new, strategy_mock do
      assert_equal full_short_url, DynamicLinks.shorten_url('https://example.com', @client)
    end

    strategy_mock.verify
  end

  test "generate_short_url returns the correct structure" do
    DynamicLinks.configure do |config|
      config.shortening_strategy = :mock
    end

    expected_short_path = 'shortened_url'
    full_short_url = "#{@client.scheme}://#{@client.hostname}/#{expected_short_path}"
    expected_response = {
      shortLink: full_short_url,
      previewLink: "#{full_short_url}?preview=true",
      warning: []
    }

    DynamicLinks.stub :shorten_url, full_short_url do
      assert_equal expected_response, DynamicLinks.generate_short_url('https://example.com', @client)
    end
  end
end
