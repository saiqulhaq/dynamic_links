require 'test_helper'

module DynamicLinks
  class RedirectsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @client = dynamic_links_clients(:one)
      @valid_hostname = @client.hostname
      host! @valid_hostname

      @original_fallback_mode = DynamicLinks.configuration.enable_fallback_mode
      @original_firebase_host = DynamicLinks.configuration.firebase_host
    end

    teardown do
      DynamicLinks.configuration.enable_fallback_mode = @original_fallback_mode
      DynamicLinks.configuration.firebase_host = @original_firebase_host
    end

    def with_tenant(client, &block)
      if defined?(::MultiTenant)
        ::MultiTenant.with(client, &block)
      else
        yield
      end
    end

    test "redirects to original URL for valid short URL" do
      short_url = dynamic_links_shortened_urls(:one)

      with_tenant(@client) do
        get shortened_url(short_url: short_url.short_url)
        assert_response :found
        assert_redirected_to short_url.url
      end
    end

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

    test "responds with not found for non-existent short URL" do
      with_tenant(@client) do
        get shortened_url(short_url: 'nonexistent')
        assert_response :not_found
        assert_match(/not found/i, @response.body)
      end
    end

    test "responds with not found for expired short URL" do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:expired_url)

        with_tenant(@client) do
          get shortened_url(short_url: short_url.short_url)
          assert_response :not_found
        end
      end
    end

    test "redirects for valid non-expired short URL" do
      Timecop.freeze(Time.zone.now) do
        short_url = dynamic_links_shortened_urls(:non_expired_url)

        with_tenant(@client) do
          get shortened_url(short_url: short_url.short_url)
          assert_response :found
          assert_redirected_to short_url.url
        end
      end
    end

    test "responds with not found if host is not in clients" do
      host! 'unknown-host.com'
      short_url = dynamic_links_shortened_urls(:one)

      with_tenant(@client) do
        get shortened_url(short_url: short_url.short_url)
        assert_response :not_found
        assert_equal 'URL not found', @response.body
      end
    end

    test "redirects to Firebase host when short URL not found and fallback mode is enabled" do
      DynamicLinks.configuration.enable_fallback_mode = true
      DynamicLinks.configuration.firebase_host = "https://k4mu4.app.goo.gl"

      with_tenant(@client) do
        get shortened_url(short_url: "nonexistent123")
        assert_response :found
        assert_redirected_to "https://k4mu4.app.goo.gl/nonexistent123"
      end
    end

    test "responds with not found when fallback mode is enabled but firebase host is blank" do
      DynamicLinks.configuration.enable_fallback_mode = true
      DynamicLinks.configuration.firebase_host = ""

      with_tenant(@client) do
        get shortened_url(short_url: "nonexistent123")
        assert_response :not_found
      end
    end
  end
end
