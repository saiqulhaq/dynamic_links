require 'test_helper'

module DynamicLinks
  class RedirectsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    test "should redirect to original URL for existing short URL" do
      short_url = dynamic_links_shortened_urls(:one)
      get shortened_url(short_url: short_url.short_url)

      assert_redirected_to short_url.url
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
