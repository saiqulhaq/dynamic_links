require 'test_helper'

module DynamicLinks
  class RedirectsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @valid_hostname = dynamic_links_clients(:one).hostname
      host! @valid_hostname

      @original_fallback_mode = DynamicLinks.configuration.enable_fallback_mode
      @original_firebase_host = DynamicLinks.configuration.firebase_host
    end

    teardown do
      DynamicLinks.configuration.enable_fallback_mode = @original_fallback_mode
      DynamicLinks.configuration.firebase_host = @original_firebase_host
    end

    test "redirects to original URL for valid short URL" do
      short_url = dynamic_links_shortened_urls(:one)
      get shortened_url(short_url: short_url.short_url)

      assert_redirected_to short_url.url
    end

    test "responds with not found for non-existent short URL" do
      get shortened_url(short_url: 'nonexistent')

      assert_response :not_found
      assert_match(/not found/i, @response.body)
    end

    test "responds with not found for expired short URL" do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:expired_url)
        get shortened_url(short_url: short_url.short_url)

        assert_response :not_found
      end
    end

    test "redirects for valid non-expired short URL" do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:non_expired_url)
        get shortened_url(short_url: short_url.short_url)

        assert_response :found
        assert_redirected_to short_url.url
      end
    end

    test "responds with not found if host is not in clients" do
      host! 'unknown-host.com'
      short_url = dynamic_links_shortened_urls(:one)
      get shortened_url(short_url: short_url.short_url)

      assert_response :not_found
      assert_equal 'URL not found', @response.body
    end

    test "redirects to Firebase host when short URL not found and fallback mode is enabled" do
      DynamicLinks.configuration.enable_fallback_mode = true
      DynamicLinks.configuration.firebase_host = "https://k4mu4.app.goo.gl"

      get shortened_url(short_url: "nonexistent123")

      assert_response :found
      assert_redirected_to "https://k4mu4.app.goo.gl/nonexistent123"
    end

    test "responds with not found when fallback mode is enabled but firebase host is blank" do
      DynamicLinks.configuration.enable_fallback_mode = true
      DynamicLinks.configuration.firebase_host = ""  # no error expected now

      get shortened_url(short_url: "nonexistent123")

      assert_response :not_found
    end
  end
end
