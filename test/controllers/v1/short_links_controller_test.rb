require "test_helper"

class DynamicLinks::V1::ShortLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = dynamic_links_clients(:one)
    @original_rest_api_setting = DynamicLinks.configuration.enable_rest_api
    @original_db_infra_strategy = DynamicLinks.configuration.db_infra_strategy
    @original_citus_enabled = ENV['CITUS_ENABLED']
    Object.const_set(:MultiTenant, Module.new)
  end

  teardown do
    DynamicLinks.configuration.enable_rest_api = @original_rest_api_setting
    DynamicLinks.configuration.db_infra_strategy = @original_db_infra_strategy
    ENV['CITUS_ENABLED'] = @original_citus_enabled
  end

  test "should create a shortened URL" do
    url = 'https://example.com'
    api_key = @client.api_key
    expected_short_link = "#{@client.scheme}://#{@client.hostname}/shortened_url"
    expected_response = {
      shortLink: expected_short_link,
      previewLink: "#{expected_short_link}?preview=true",
      warning: []
    }.as_json

    DynamicLinks.stub :generate_short_url, expected_response do
      post '/v1/shortLinks', params: { url: url, api_key: api_key }

      assert_response :created
      assert_equal "application/json; charset=utf-8", @response.content_type
      assert_equal expected_response, JSON.parse(@response.body)
    end
  end

  test "should respond with unauthorized for invalid API key" do
    post '/v1/shortLinks', params: { url: 'https://example.com', api_key: 'invalid' }
    assert_response :unauthorized
  end

  test "should respond with bad request for invalid URL" do
    DynamicLinks.stub :generate_short_url, ->(_url, _client) { raise DynamicLinks::InvalidURIError } do
      post '/v1/shortLinks', params: { url: 'invalid_url', api_key: @client.api_key }
      assert_response :bad_request
    end
  end

  test "should return internal server error if multi_tenant block raises an error" do
    begin
      DynamicLinks.stubs(:generate_short_url).raises(StandardError)
      post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }

      assert_response :internal_server_error
      assert_equal '{"error":"An error occurred while processing your request"}', response.body
    ensure
      DynamicLinks.unstub(:generate_short_url)
    end
  end

  test "should not allow short URL creation when REST API is disabled" do
    DynamicLinks.configuration.enable_rest_api = false

    post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }
    assert_response :forbidden
    assert_includes @response.body, 'REST API feature is disabled'
  end

  #if defined?(::MultiTenant)
    test "should use MultiTenant.with when db_infra_strategy is :sharding" do
      ENV['CITUS_ENABLED'] = 'true'
      DynamicLinks.configuration.db_infra_strategy = :sharding
      ::MultiTenant.expects(:with).with(@client).once
      url = 'https://example.com/'
      api_key = @client.api_key
      post '/v1/shortLinks', params: { url: url, api_key: api_key }
    end

    test "should use MultiTenant.with when db_infra_strategy is :sharding and log error" do
      ENV['CITUS_ENABLED'] = 'false'

      DynamicLinks.configuration.db_infra_strategy = :sharding

      # Ensure that MultiTenant is not defined (simulating it not being installed)
      originally_defined = defined?(::MultiTenant)
      Object.send(:remove_const, :MultiTenant) if originally_defined

      # Expect the warning message to be logged
      Rails.logger.expects(:warn).with('MultiTenant gem is not installed. Please install it to use sharding strategy')

      # Make the request
      url = 'https://example.com/'
      api_key = @client.api_key
      post '/v1/shortLinks', params: { url: url, api_key: api_key }

      # Re-define MultiTenant if it was originally defined
      Object.const_set(:MultiTenant, Module.new) if originally_defined
    end

    test "should not use MultiTenant.with when db_infra_strategy is not :sharding" do
      DynamicLinks.configuration.db_infra_strategy = :standard
      url = 'https://example.com/'
      api_key = @client.api_key
      ::MultiTenant.expects(:with).with(@client).never
      post '/v1/shortLinks', params: { url: url, api_key: api_key }
    end
  #end
end
