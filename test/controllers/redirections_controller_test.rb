require 'test_helper'

module DynamicLinks
  class RedirectsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should redirect to original URL for existing short URL" do
      short_url = dynamic_links_shortened_urls(:one)
      user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'
      referrer = 'https://shortener-url-one.com'
      get shortened_url(short_url: short_url.short_url),
        headers: { 'User-Agent': user_agent, 'Referer': referrer }

      assert_redirected_to short_url.url
      assert_response :found

      ahoy_event = Ahoy::Event.last
      assert_equal "Link Clicked", ahoy_event.name
      assert_equal short_url.short_url, ahoy_event.properties["shortened_url"]
      assert_equal user_agent, ahoy_event.properties["user_agent"]
      assert_equal referrer, ahoy_event.properties["referrer"]
    end

    test "should respond with not found for non-existing short URL" do
      get shortened_url(short_url: 'nonexistent')

      assert_response :not_found
    end

    test "should respond with not found for expired short URL" do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:expired_url)
        get shortened_url(short_url: short_url.short_url)

        assert_response :not_found
      end
    end

    test "should respond with found for non-expired short URL" do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:non_expired_url)
        get shortened_url(short_url: short_url.short_url)

        assert_response :found
      end
    end
  end
end
