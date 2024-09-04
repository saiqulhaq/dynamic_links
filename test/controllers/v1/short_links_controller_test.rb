require "test_helper"

class DynamicLinks::V1::ShortLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = dynamic_links_clients(:one)
    @original_rest_api_setting = DynamicLinks.configuration.enable_rest_api
    @original_db_infra_strategy = DynamicLinks.configuration.db_infra_strategy
  end

  teardown do
    DynamicLinks.configuration.enable_rest_api = @original_rest_api_setting
    DynamicLinks.configuration.db_infra_strategy = @original_db_infra_strategy
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
    DynamicLinks.stubs(:generate_short_url).raises(StandardError)
    post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }

    assert_response :internal_server_error
    assert_equal '{"error":"An error occurred while processing your request"}', response.body
  end

  test "should not allow short URL creation when REST API is disabled" do
    DynamicLinks.configuration.enable_rest_api = false

    post '/v1/shortLinks', params: { url: 'https://example.com', api_key: @client.api_key }
    assert_response :forbidden
    assert_includes @response.body, 'REST API feature is disabled'
  end

  if defined?(::MultiTenant)
    test "should use MultiTenant.with when db_infra_strategy is :sharding" do
      DynamicLinks.configuration.db_infra_strategy = :sharding
      ::MultiTenant.expects(:with).with(@client).once
      url = 'https://example.com/'
      api_key = @client.api_key
      post '/v1/shortLinks', params: { url: url, api_key: api_key }
    end

    test "should not use MultiTenant.with when db_infra_strategy is not :sharding" do
      DynamicLinks.configuration.db_infra_strategy = :standard
      url = 'https://example.com/'
      api_key = @client.api_key
      ::MultiTenant.expects(:with).with(@client).never
      post '/v1/shortLinks', params: { url: url, api_key: api_key }
    end
  end
end
